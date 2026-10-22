import Foundation
import OpenAPIRuntime
import PeatedAPI

public protocol BottlePhotoRepositoryProtocol: Sendable {
    /// Uploads the photo and waits for the final result. `onProgress` receives each
    /// event the server sends first. Cancelling the task closes the stream, which
    /// stops the server's work.
    func identifyBottlePhoto(
        fileDataUrl: String,
        idempotencyKey: String,
        onProgress: @escaping @Sendable (BottlePhotoProgress) async -> Void
    ) async throws -> BottlePhotoIdentification

    func createBottleFromPhoto(createToken: String) async throws -> BottlePhotoCreation
}

public actor BottlePhotoIdentificationRepository: BottlePhotoRepositoryProtocol,
    BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func identifyBottlePhoto(
        fileDataUrl: String,
        idempotencyKey: String,
        onProgress: @escaping @Sendable (BottlePhotoProgress) async -> Void
    ) async throws -> BottlePhotoIdentification {
        let client = await client
        guard let imageData = Self.decodeDataURL(fileDataUrl) else {
            throw APIError.requestFailed("The bottle photo could not be read.")
        }
        typealias Part = Operations.identifyTastingBottleFromPhoto.Input.Body.multipartFormPayload
        let multipartBody: MultipartBody<Part> = [
            .file(.init(
                payload: .init(body: HTTPBody(imageData)),
                filename: "bottle.jpg"
            )),
            .idempotencyKey(.init(
                payload: .init(body: HTTPBody(idempotencyKey))
            ))
        ]
        let response = try await client.identifyTastingBottleFromPhoto(
            body: .multipartForm(multipartBody)
        )

        guard case let .ok(okResponse) = response else {
            throw Self.identificationError(for: response)
        }
        guard case let .text_event_hyphen_stream(body) = okResponse.body else {
            throw APIError.invalidResponse
        }

        let identification = try await Self.readEvents(body, onProgress: onProgress)
        if case let .matched(bottle) = identification.outcome {
            await cache(bottle)
        }
        return identification
    }

    private static func decodeDataURL(_ value: String) -> Data? {
        guard value.hasPrefix("data:image/"),
              let separator = value.firstIndex(of: ","),
              value[..<separator].hasSuffix(";base64")
        else {
            return nil
        }

        return Data(base64Encoded: String(value[value.index(after: separator)...]))
    }

    public func createBottleFromPhoto(createToken: String) async throws -> BottlePhotoCreation {
        let client = await client
        let response = try await client.createTastingBottleFromPhotoIdentification(
            body: .json(.init(createToken: createToken))
        )

        guard case let .ok(okResponse) = response else {
            throw Self.creationError(for: response)
        }
        guard case let .json(payload) = okResponse.body else {
            throw APIError.invalidResponse
        }

        let bottle = Bottle(from: payload.bottle)
        await cache(bottle)
        return BottlePhotoCreation(
            bottle: bottle,
            warnings: payload.warnings?.map(\.message) ?? []
        )
    }

    private func cache(_ bottle: Bottle) async {
        await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle)
        await SnapshotStore.upsertBottle(BottleSnapshot(
            id: bottle.id,
            fullName: bottle.fullName,
            brandId: bottle.brand.id,
            brandName: bottle.brand.name,
            imageUrl: bottle.imageUrl
        ))
    }
}

extension BottlePhotoIdentificationRepository {
    typealias Payload = Components.Schemas.identifyTastingBottleFromPhotoDoneEventData
    typealias ProgressPayload = Components.Schemas.identifyTastingBottleFromPhotoMessageEventData
    typealias ProposedBottle = Payload.classificationPayload.Value2Payload.decisionPayload.Value2Payload
        .proposedBottlePayload

    /// Reads server-sent events until `done`. Keep-alive comments carry no data
    /// and are skipped. An `error` event means the lookup failed after the
    /// stream started.
    static func readEvents(
        _ body: HTTPBody,
        onProgress: @Sendable (BottlePhotoProgress) async -> Void
    ) async throws -> BottlePhotoIdentification {
        let decoder = makeDecoder()
        for try await event in body.asDecodedServerSentEvents() {
            guard let data = event.data.map({ Data($0.utf8) }) else { continue }

            switch event.event {
            case "done":
                return try map(decoder.decode(Payload.self, from: data))
            case "error":
                throw streamError(try? decoder.decode(StreamError.self, from: data))
            case "message", nil:
                // Progress only improves the wait. The `done` event is the result,
                // so a progress event this version cannot read is skipped.
                if let progress = try? progress(from: data, decoder: decoder) {
                    await onProgress(progress)
                }
            default:
                continue
            }
        }
        try Task.checkCancellation()
        throw APIError.invalidResponse
    }

    /// Returns nil for progress types this app version does not know.
    static func progress(from data: Data, decoder: JSONDecoder) throws -> BottlePhotoProgress? {
        struct Kind: Decodable {
            let type: String
        }

        switch try decoder.decode(Kind.self, from: data).type {
        case "photo":
            let payload = try decoder.decode(ProgressPayload.Value1Payload.self, from: data)
            return .photo(pendingImageId: payload.pendingImage.id)
        case "label":
            return .labelRead
        case "candidates":
            let payload = try decoder.decode(ProgressPayload.Value3Payload.self, from: data)
            return .candidates(payload.bottles.map(Bottle.init(from:)))
        case "step":
            let payload = try decoder.decode(ProgressPayload.Value4Payload.self, from: data)
            return switch payload.step {
            case .checking_peated: .step(.checkingPeated)
            case .checking_web: .step(.checkingWeb)
            case .comparing: .step(.comparing)
            }
        default:
            return nil
        }
    }

    /// The error body oRPC sends in an `error` event.
    struct StreamError: Decodable {
        let code: String?
    }

    static func streamError(_ error: StreamError?) -> APIError {
        switch error?.code {
        case "SERVICE_UNAVAILABLE":
            .requestFailed("Photo identification is temporarily unavailable. Try again later.")
        default:
            .serverError(500, nil)
        }
    }

    /// Event data skips the generated client's decoder, so match its date handling.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let transcoder = CustomDateTranscoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            try transcoder.decode(decoder.singleValueContainer().decode(String.self))
        }
        return decoder
    }

    static func identificationError(
        for response: Operations.identifyTastingBottleFromPhoto.Output
    ) -> APIError {
        switch response {
        case .ok:
            .invalidResponse
        case .badRequest:
            .requestFailed("Use a clear photo of one bottle label and try again.")
        case .unauthorized:
            .unauthorized
        case .forbidden:
            .requestFailed("Photo identification is unavailable for this account.")
        case .notFound:
            .notFound
        case .conflict:
            .requestFailed("That photo is already being processed. Try again in a moment.")
        case .contentTooLarge:
            .requestFailed("That photo is too large. Choose a smaller image.")
        case .serviceUnavailable:
            .requestFailed("Photo identification is temporarily unavailable. Try again later.")
        case .internalServerError:
            .serverError(500, nil)
        case let .undocumented(statusCode, _):
            .unexpectedResponse(statusCode)
        }
    }

    static func creationError(
        for response: Operations.createTastingBottleFromPhotoIdentification.Output
    ) -> APIError {
        switch response {
        case .ok:
            .invalidResponse
        case .badRequest:
            .requestFailed("That bottle proposal is no longer valid. Scan it again.")
        case .unauthorized:
            .unauthorized
        case .forbidden:
            .requestFailed("A verified account is required to add a bottle.")
        case .notFound:
            .notFound
        case .conflict:
            .requestFailed("A matching bottle was created already. Search for it instead.")
        case .contentTooLarge:
            .requestFailed("The bottle proposal is too large.")
        case .internalServerError:
            .serverError(500, nil)
        case let .undocumented(statusCode, _):
            .unexpectedResponse(statusCode)
        }
    }

    static func map(_ payload: Payload) -> BottlePhotoIdentification {
        let fields = payload.imageEvidence.fieldCandidates
        let brandName = fields?.brand?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bottleName = fields?.expression?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let decision = payload.classification.value2?.decision
        // The no_match variant (`value3`) only requires `action`, so it decodes
        // alongside every other variant. The action string picks the variant.
        let action = decision?.value3?.action.value as? String
        let matched = action == "match" ? decision?.value1?.matchedBottle : nil
        let proposed = action == "create_bottle" ? decision?.value2?.proposedBottle : nil
        let proposedBrandName = proposed?.brand.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let proposedBottleName = proposed?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let manualInput = CreateBottleInput(
            name: proposedBottleName ?? bottleName,
            brandName: proposedBrandName ?? brandName,
            category: proposed?.category.flatMap { BottleCategory(rawValue: $0.rawValue) }
                ?? fields?.category.flatMap { BottleCategory(rawValue: $0.value.rawValue) },
            statedAge: proposed?.statedAge.map { Int($0) } ?? fields?.statedAge.map(\.value),
            abv: proposed?.abv ?? fields?.abv?.value,
            edition: nonEmpty(proposed?.edition ?? fields?.edition?.value),
            distillers: makeDistillers(proposed: proposed?.distillers, fields: fields),
            singleCask: proposed?.singleCask ?? fields?.singleCask?.value ?? false,
            caskStrength: proposed?.caskStrength ?? fields?.caskStrength?.value ?? false,
            vintageYear: proposed?.vintageYear.map { Int($0) } ?? fields?.vintageYear?.value,
            releaseYear: proposed?.releaseYear.map { Int($0) } ?? fields?.releaseYear?.value
        )

        // Matches the web resolver: a match the server downgraded to manual
        // search still shows the matched bottle for the user to confirm.
        let outcome: BottlePhotoIdentification.Outcome =
            if let matched {
                .matched(Bottle(from: matched))
            } else if let proposed,
                      payload.suggestedNextStep == .confirm_create,
                      let createToken = payload.createToken {
                .proposed(
                    BottlePhotoProposal(
                        name: proposed.name,
                        brandName: proposed.brand.name,
                        category: proposed.category.flatMap {
                            BottleCategory(rawValue: $0.rawValue)
                        },
                        statedAge: proposed.statedAge.map { Int($0) },
                        abv: proposed.abv
                    ),
                    createToken: createToken
                )
            } else if proposed != nil || (action == "no_match" && hasLabelDetails(fields)) {
                .notFound
            } else {
                .unidentified
            }

        return BottlePhotoIdentification(
            pendingImageId: payload.pendingImage.id,
            pendingImageUrl: payload.pendingImage.imageUrl,
            facts: makeFacts(fields),
            searchQuery: [brandName, bottleName]
                .filter { !$0.isEmpty }
                .joined(separator: " "),
            manualBottleInput: manualInput == CreateBottleInput(name: "", brandName: "") ? nil : manualInput,
            outcome: outcome
        )
    }

    /// Proposed distillers keep their catalog id. Label text only has names, so the
    /// server creates those distilleries unless the user picks an existing one.
    static func makeDistillers(
        proposed: ProposedBottle.distillersPayload?,
        fields: Payload.imageEvidencePayload.fieldCandidatesPayload?
    ) -> [CreateBottleInput.Distiller] {
        if let proposed, !proposed.isEmpty {
            return proposed.compactMap { distiller in
                guard let name = nonEmpty(distiller.name) else { return nil }
                return distiller.id.map { .existing(id: $0, name: name) } ?? .new(name: name)
            }
        }
        return (fields?.distillery?.value ?? []).compactMap { nonEmpty($0).map { .new(name: $0) } }
    }

    static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Label details that identify a specific bottle, as opposed to its type.
    static func hasLabelDetails(_ fields: Payload.imageEvidencePayload.fieldCandidatesPayload?) -> Bool {
        guard let fields else { return false }

        let text = [fields.brand?.value, fields.expression?.value, fields.edition?.value, fields.caskNumber?.value]
        let hasText = text.contains { value in
            !(value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
        return hasText || [
            fields.statedAge != nil,
            fields.abv != nil,
            fields.vintageYear != nil,
            fields.bottlingYear != nil,
            fields.releaseYear != nil
        ].contains(true)
    }

    static func makeFacts(_ fields: Payload.imageEvidencePayload.fieldCandidatesPayload?) -> [BottlePhotoFact] {
        guard let fields else { return [] }

        return [
            fact("Brand", fields.brand?.value),
            fact("Bottle", fields.expression?.value),
            fact("Series", fields.series?.value),
            fact("Distillers", fields.distillery?.value.joined(separator: ", ")),
            fact("Bottler", fields.bottler?.value),
            fact("Type", BottleDisplayName.categoryName(fields.category?.value.rawValue)),
            fact("Age", fields.statedAge.map { "\(Int($0.value)) years" }),
            fact("ABV", fields.abv.map { String(format: "%g%%", $0.value) }),
            fact("Edition", fields.edition?.value),
            fact("Vintage", fields.vintageYear.map { String(Int($0.value)) }),
            fact("Release", fields.releaseYear.map { String(Int($0.value)) }),
            fact("Cask", fields.caskNumber?.value),
            fact("Cask Strength", fields.caskStrength.map { $0.value ? "Yes" : "No" }),
            fact("Single Cask", fields.singleCask.map { $0.value ? "Yes" : "No" })
        ].compactMap(\.self)
    }

    static func fact(_ label: String, _ value: String?) -> BottlePhotoFact? {
        guard let value, !value.isEmpty else { return nil }
        return BottlePhotoFact(label: label, value: value)
    }
}
