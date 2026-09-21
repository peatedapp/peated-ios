import Foundation
@testable import Peated
import Testing

struct AppleSignInCredentialTests {
    @Test
    func formattedNameJoinsComponents() {
        var components = PersonNameComponents()
        components.givenName = "Jane"
        components.familyName = "Doe"

        #expect(AppleSignInCredential.formattedName(components) == "Jane Doe")
    }

    @Test
    func formattedNameIsNilWhenAppleSendsNoName() {
        #expect(AppleSignInCredential.formattedName(nil) == nil)
        #expect(AppleSignInCredential.formattedName(PersonNameComponents()) == nil)
    }
}
