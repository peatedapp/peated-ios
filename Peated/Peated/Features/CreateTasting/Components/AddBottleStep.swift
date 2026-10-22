/// The steps of the Add Bottle form.
///
/// Titles and grouping follow the web create wizard (`bottleForm.tsx`). The web's
/// "Cask" and "Photo" steps are left out because iOS does not collect those fields.
enum AddBottleStep: Int, CaseIterable {
    case bottle
    case madeBy
    case release
    case dates
    case production

    var title: String {
        switch self {
        case .bottle: "Bottle"
        case .madeBy: "Made by"
        case .release: "Release"
        case .dates: "Dates"
        case .production: "Production"
        }
    }

    /// One-based, for the step count.
    var number: Int {
        rawValue + 1
    }

    var previous: AddBottleStep? {
        AddBottleStep(rawValue: rawValue - 1)
    }

    var next: AddBottleStep? {
        AddBottleStep(rawValue: rawValue + 1)
    }

    var isLast: Bool {
        next == nil
    }
}
