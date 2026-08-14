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
                        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                    } else {
                        SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
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
                }
                .buttonStyle(.plain)
            }
            .inputBox(state: isFocused ? .focused : .normal)
        }
    }
}
