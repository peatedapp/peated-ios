/// Mirror of `Peated/Common/AccessibilityID.swift`.
///
/// The UI test bundle runs in its own process and cannot import the app
/// module, so the identifiers are repeated here. Keep both files identical.
enum AccessibilityID {
    enum Auth {
        static let signUpLink = "auth.signUpLink"
        static let username = "auth.signUp.username"
        static let email = "auth.signUp.email"
        static let password = "auth.signUp.password"
        static let termsToggle = "auth.signUp.termsToggle"
        static let termsLink = "auth.signUp.termsLink"
        static let privacyLink = "auth.signUp.privacyLink"
        static let createAccount = "auth.signUp.createAccount"
    }

    enum Terms {
        static let accept = "terms.accept"
    }

    enum CreateTasting {
        static let cancel = "createTasting.cancel"
        static let back = "createTasting.back"
        static let continueButton = "createTasting.continue"
        static let submit = "createTasting.submit"
        static let bottleSearch = "createTasting.bottleSearch"
        static let bottleResult = "createTasting.bottleResult"
        static let scanBarcode = "createTasting.scanBarcode"
        static let atHome = "createTasting.location.atHome"
        static let takePhoto = "createTasting.photos.takePhoto"

        static func rating(_ band: String) -> String {
            "createTasting.rating.\(band)"
        }
    }

    enum Permission {
        static let deniedNotice = "permission.deniedNotice"
        static let openSettings = "permission.openSettings"
    }
}
