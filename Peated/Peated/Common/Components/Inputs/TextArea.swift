import SwiftUI

// MARK: - TextArea

/// Reusable multi-line input with placeholder, theming, and focus/error handling.
struct TextArea: View {
    let label: String?
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var disabled: Bool = false
    var error: String?
    var helper: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let label, !label.isEmpty {
                FieldLabel(text: label)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .foregroundColor(.text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)

                if text.isEmpty, !isFocused {
                    Text(placeholder)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .inputBox(state: inputState)
            .disabled(disabled)

            if let error, !error.isEmpty {
                // Validation uses the semibold 13pt of the field-label role, like the web.
                Text(error)
                    .font(.peatedFieldLabel)
                    .foregroundColor(.danger)
            } else if let helper, !helper.isEmpty {
                Text(helper)
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var inputState: InputBox.State {
        if disabled {
            return .disabled
        }
        if error != nil {
            return .error
        }
        return isFocused ? .focused : .normal
    }
}
