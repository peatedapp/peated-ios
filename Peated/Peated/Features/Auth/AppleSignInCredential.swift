import AuthenticationServices
import Foundation

/// The parts of an Apple authorization that the Peated API exchanges for a session.
struct AppleSignInCredential: Equatable {
    /// Identity token (JWT) whose audience is the app's bundle ID.
    let identityToken: String
    /// Apple provides the name only on the first authorization for this Apple ID.
    let fullName: String?

    enum Failure: LocalizedError {
        case unexpectedCredential
        case missingIdentityToken

        var errorDescription: String? {
            switch self {
            case .unexpectedCredential, .missingIdentityToken:
                "Apple sign-in did not return a usable credential"
            }
        }
    }

    init(identityToken: String, fullName: String?) {
        self.identityToken = identityToken
        self.fullName = fullName
    }

    init(authorization: ASAuthorization) throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw Failure.unexpectedCredential
        }
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8),
              !token.isEmpty
        else {
            throw Failure.missingIdentityToken
        }
        self.init(identityToken: token, fullName: Self.formattedName(credential.fullName))
    }

    /// Joins the name components Apple sends into one display name, or nil when Apple sent none.
    static func formattedName(_ components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}
