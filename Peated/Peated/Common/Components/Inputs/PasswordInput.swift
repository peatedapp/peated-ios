import SwiftUI

// MARK: - PasswordInput

/// Minimal reusable password field with eye toggle, styled via InputBox.
struct PasswordInput: View {
    let label: String?
    let placeholder: String
    @Binding var text: String
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)?

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label, !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 8) {
                Group {
                    if isVisible {
                        TextField(fieldLabel, text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                    } else {
                        SecureField(fieldLabel, text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                    }
                }
                .textFieldStyle(.plain)
                .foregroundColor(.text)
                .textContentType(.password)
                .focused($isFocused)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }

                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
