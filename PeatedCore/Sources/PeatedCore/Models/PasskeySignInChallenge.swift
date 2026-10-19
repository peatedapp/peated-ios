import Foundation

/// The server's WebAuthn options for one passkey sign-in.
public struct PasskeySignInChallenge: Sendable, Equatable {
    /// The bytes the passkey signs.
    public let challenge: Data
    /// The domain that owns the passkey, such as `peated.com`.
    public let relyingPartyID: String
    /// The passkeys the server accepts. Empty means any passkey for the domain.
    public let allowedCredentialIDs: [Data]
    /// The WebAuthn user verification preference: `required`, `preferred`, or `discouraged`.
    public let userVerification: String?
    /// The server's signed copy of the challenge. It goes back with the assertion,
    /// so the server can check the challenge without storing it.
    let signedChallenge: String
}
