import Foundation

/// A passkey's signed answer to a `PasskeySignInChallenge`.
public struct PasskeyAssertion: Sendable, Equatable {
    public let credentialID: Data
    public let clientDataJSON: Data
    public let authenticatorData: Data
    public let signature: Data
    /// The account the passkey belongs to, when the authenticator reports it.
    public let userHandle: Data?

    public init(
        credentialID: Data,
        clientDataJSON: Data,
        authenticatorData: Data,
        signature: Data,
        userHandle: Data?
    ) {
        self.credentialID = credentialID
        self.clientDataJSON = clientDataJSON
        self.authenticatorData = authenticatorData
        self.signature = signature
        self.userHandle = userHandle
    }
}
