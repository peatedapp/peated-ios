import Foundation

/// A new passkey's answer to a `PasskeyRegistrationChallenge`.
public struct PasskeyRegistration: Sendable, Equatable {
    public let credentialID: Data
    public let clientDataJSON: Data
    /// The CBOR attestation object that carries the new public key.
    public let attestationObject: Data

    public init(credentialID: Data, clientDataJSON: Data, attestationObject: Data) {
        self.credentialID = credentialID
        self.clientDataJSON = clientDataJSON
        self.attestationObject = attestationObject
    }
}
