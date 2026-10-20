import Foundation

/// The server's WebAuthn options for creating the passkey of a new account.
public struct PasskeyRegistrationChallenge: Sendable, Equatable {
    /// The bytes the new passkey signs.
    public let challenge: Data
    /// The domain that will own the passkey, such as `peated.com`.
    public let relyingPartyID: String
    /// The account handle the server assigned, stored inside the passkey.
    public let userID: Data
    /// The name the system sheet shows for the passkey, the new username.
    public let userName: String
    /// The WebAuthn user verification preference: `required`, `preferred`, or `discouraged`.
    public let userVerification: String?
    /// The server's signed copy of the challenge, sent back with the new passkey.
    let signedChallenge: String
}
