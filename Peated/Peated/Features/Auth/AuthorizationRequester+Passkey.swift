import AuthenticationServices
import PeatedCore

extension AuthorizationRequester where Credential == PasskeyAssertion {
    convenience init() {
        self.init(decode: Self.passkeyAssertion(from:))
    }

    /// Shows the system passkey sheet for a peated.com passkey. iOS offers only
    /// passkeys for domains listed in the app's `webcredentials` entitlement.
    func requestPasskey(for challenge: PasskeySignInChallenge) async throws -> PasskeyAssertion? {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: challenge.relyingPartyID
        )
        let request = provider.createCredentialAssertionRequest(challenge: challenge.challenge)
        request.allowedCredentials = challenge.allowedCredentialIDs.map {
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
        }
        if let userVerification = challenge.userVerification {
            request.userVerificationPreference = .init(rawValue: userVerification)
        }
        return try await self.request(request)
    }

    private nonisolated static func passkeyAssertion(from authorization: ASAuthorization) throws -> PasskeyAssertion {
        guard let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion,
              let authenticatorData = credential.rawAuthenticatorData,
              let signature = credential.signature
        else {
            throw PasskeyFailure.unusableCredential
        }
        return PasskeyAssertion(
            credentialID: credential.credentialID,
            clientDataJSON: credential.rawClientDataJSON,
            authenticatorData: authenticatorData,
            signature: signature,
            userHandle: credential.userID
        )
    }
}

private enum PasskeyFailure: LocalizedError {
    case unusableCredential

    var errorDescription: String? {
        "The passkey did not return a usable sign-in"
    }
}
