import SwiftUI
import UIKit

// MARK: - TextInput

/// Reusable, theme-aware text input with optional label/icon/unit and error/helper text.
struct TextInput: View {
    // Content
    let label: String?
    let placeholder: String
    @Binding var text: String
    var leadingSystemImage: String?
    var unit: String?
    var isSecure: Bool = false

    // Behavior
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var submitLabel: SubmitLabel = .done
    var autocorrection: Bool = true
    var capitalization: TextInputAutocapitalization = .sentences
    var disabled: Bool = false
    var error: String?
    var helper: String?
    var onSubmit: (() -> Void)?

    // Focus (internal; external binding optional for coordinated form navigation)
    var isFocused: FocusState<Bool>.Binding?
    @FocusState private var internalFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label, !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 8) {
                if let icon = leadingSystemImage {
                    Image(systemName: icon)
                        .foregroundColor(.textSecondary)
                }

                Group {
                    if isSecure {
                        SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                    } else {
                        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                    }
                }
                .textFieldStyle(.plain)
                .foregroundColor(.text)
                .keyboardType(keyboard)
                .submitLabel(submitLabel)
                .autocorrectionDisabled(!autocorrection)
                .textInputAutocapitalization(capitalization)
                .textContentType(contentType)
                .onSubmit { onSubmit?() }
                .focused(focusBinding)

                if let unit, !unit.isEmpty {
                    Text(unit)
                        .foregroundColor(.textSecondary)
                }
            }
            .inputBox(state: inputState)
            .disabled(disabled)

            if let error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.danger)
            } else if let helper, !helper.isEmpty {
                Text(helper)
                    .font(.caption)
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
        let focused = isFocused?.wrappedValue ?? internalFocused
        return focused ? .focused : .normal
    }

    private var focusBinding: FocusState<Bool>.Binding {
        isFocused ?? $internalFocused
    }
}
