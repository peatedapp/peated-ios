import Foundation
import OpenAPIRuntime
import PeatedAPI

public protocol BottlePhotoRepositoryProtocol: Sendable {
    func identifyBottlePhoto(
        fileDataUrl: String,
        idempotencyKey: String
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
        idempotencyKey: String
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
        guard case let .json(payload) = okResponse.body else {
            throw APIError.invalidResponse
        }

        let identification = Self.map(payload)
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
    typealias Payload = Operations.identifyTastingBottleFromPhoto.Output.Ok.Body.jsonPayload

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
        let proposed = payload.classification.value2?.decision.value2?.proposedBottle
        let proposedBrandName = proposed?.brand.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let proposedBottleName = proposed?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let manualBrandName = proposedBrandName ?? brandName
        let manualBottleName = proposedBottleName ?? bottleName
        let manualCategory = proposed?.category.flatMap { BottleCategory(rawValue: $0.rawValue) }
            ?? fields?.category.flatMap { BottleCategory(rawValue: $0.value.rawValue) }
        let manualInput = manualBrandName.isEmpty || manualBottleName.isEmpty
            ? nil
            : CreateBottleInput(
                name: manualBottleName,
                brandName: manualBrandName,
                category: manualCategory,
                statedAge: proposed?.statedAge.map { Int($0) } ?? fields?.statedAge.map(\.value),
                abv: proposed?.abv ?? fields?.abv?.value
            )

        let outcome: BottlePhotoIdentification.Outcome = switch payload.suggestedNextStep {
        case .confirm_match:
            if let matched = payload.classification.value2?.decision.value1?.matchedBottle {
                .matched(Bottle(from: matched))
            } else {
                .manual
            }
        case .confirm_create:
            if let proposed, let createToken = payload.createToken {
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
            } else {
                .manual
            }
        case .manual_search:
            .manual
        }

        return BottlePhotoIdentification(
            pendingImageId: payload.pendingImage.id,
            pendingImageUrl: payload.pendingImage.imageUrl,
            facts: makeFacts(fields),
            searchQuery: [brandName, bottleName]
                .filter { !$0.isEmpty }
                .joined(separator: " "),
            manualBottleInput: manualInput,
            photoSuitabilityReason: payload.imageEvidence.photoSuitability.reason,
            outcome: outcome
        )
    }

    static func makeFacts(_ fields: Payload.imageEvidencePayload.fieldCandidatesPayload?) -> [BottlePhotoFact] {
        guard let fields else { return [] }

        return [
            fact("Brand", fields.brand?.value),
            fact("Bottle", fields.expression?.value),
            fact("Series", fields.series?.value),
            fact("Distillers", fields.distillery?.value.joined(separator: ", ")),
            fact("Bottler", fields.bottler?.value),
            fact("Type", fields.category?.value.rawValue.replacingOccurrences(of: "_", with: " ").capitalized),
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
