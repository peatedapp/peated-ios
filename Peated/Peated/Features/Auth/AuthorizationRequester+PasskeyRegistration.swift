import AuthenticationServices
import PeatedCore

extension AuthorizationRequester where Credential == PasskeyRegistration {
    convenience init() {
        self.init(decode: Self.passkeyRegistration(from:))
    }

    /// Shows the system sheet that saves a new peated.com passkey for a new account.
    func requestPasskeyRegistration(for challenge: PasskeyRegistrationChallenge) async throws -> PasskeyRegistration? {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: challenge.relyingPartyID
        )
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge.challenge,
            name: challenge.userName,
            userID: challenge.userID
        )
        if let userVerification = challenge.userVerification {
            request.userVerificationPreference = .init(rawValue: userVerification)
        }
        return try await self.request(request)
    }

    private nonisolated static func passkeyRegistration(
        from authorization: ASAuthorization
    ) throws -> PasskeyRegistration {
        guard let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration,
              let attestationObject = credential.rawAttestationObject
        else {
            throw PasskeyRegistrationFailure.unusableCredential
        }
        return PasskeyRegistration(
            credentialID: credential.credentialID,
            clientDataJSON: credential.rawClientDataJSON,
            attestationObject: attestationObject
        )
    }
}

private enum PasskeyRegistrationFailure: LocalizedError {
    case unusableCredential

    var errorDescription: String? {
        "The new passkey could not be saved"
    }
}
