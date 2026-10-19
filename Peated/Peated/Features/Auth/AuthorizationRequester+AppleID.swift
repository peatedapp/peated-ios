import AuthenticationServices

extension AuthorizationRequester where Credential == AppleSignInCredential {
    convenience init() {
        self.init(decode: AppleSignInCredential.init(authorization:))
    }

    /// A sign-in asks for the name and email. A confirmation passes no scopes,
    /// because it needs only the authorization code.
    func requestAppleID(scopes: [ASAuthorization.Scope] = []) async throws -> AppleSignInCredential? {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = scopes
        return try await self.request(request)
    }
}
