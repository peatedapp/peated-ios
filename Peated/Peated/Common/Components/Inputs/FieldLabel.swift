import SwiftUI

/// A field's label, with the web's italic "Required" or "Optional" marker beside it.
struct FieldLabel: View {
    enum Requirement {
        case required
        case optional

        var title: String {
            switch self {
            case .required: "Required"
            case .optional: "Optional"
            }
        }
    }

    let text: String
    var requirement: Requirement?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.small) {
            Text(text)
                .font(.peatedFieldLabel)
                .foregroundColor(.brandEmphasis)

            if let requirement {
                Text(requirement.title)
                    .font(.peatedFieldMarker)
                    .foregroundColor(requirement == .required ? .brandEmphasis : .textSecondary)
            }
        }
    }
}
