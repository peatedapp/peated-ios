import SwiftUI

// MARK: - PasswordInput

/// Minimal reusable password field with eye toggle, styled via InputBox.
struct PasswordInput: View {
    let label: String?
    let placeholder: String
    @Binding var text: String
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)?
    /// Stable identifier for UI tests. See `AccessibilityID`.
    var identifier: String?

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let label, !label.isEmpty {
                FieldLabel(text: label)
            }

            HStack(spacing: 8) {
                Group {
                    if isVisible {
                        TextField(fieldLabel, text: $text, prompt: Text(placeholder).foregroundColor(.textSecondary))
                            .font(.peatedInput)
                    } else {
                        // In Karla a secure field is 19pt tall, which the accessibility audit
                        // flags as too small to tap. It shows only bullets, so it keeps the
                        // system font and only the placeholder uses the reading face.
                        SecureField(
                            fieldLabel,
                            text: $text,
                            prompt: Text(placeholder).font(.peatedInput).foregroundColor(.textSecondary)
                        )
                    }
                }
                .textFieldStyle(.plain)
                .foregroundColor(.text)
                .textContentType(.password)
                .focused($isFocused)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }
                .accessibilityIdentifier(identifier ?? "")

                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // Keep a 44pt target without making the field taller than the others.
                .padding(.vertical, -10)
                .padding(.trailing, -12)
                .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
            .inputBox(state: isFocused ? .focused : .normal)
        }
    }

    private var fieldLabel: String {
        guard let label, !label.isEmpty else {
            return placeholder
        }
        return label
    }
}
