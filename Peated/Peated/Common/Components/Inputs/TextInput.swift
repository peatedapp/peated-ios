import SwiftUI
import UIKit

// MARK: - TextInput

/// Reusable, theme-aware text input with optional label/icon/unit and error/helper text.
struct TextInput: View {
    // Content
    let label: String?
    var requirement: FieldLabel.Requirement?
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
    /// Stable identifier for UI tests. See `AccessibilityID`.
    var identifier: String?

    // Focus (internal; external binding optional for coordinated form navigation)
    var isFocused: FocusState<Bool>.Binding?
    @FocusState private var internalFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let label, !label.isEmpty {
                FieldLabel(text: label, requirement: requirement)
            }

            HStack(spacing: 8) {
                if let icon = leadingSystemImage {
                    Image(systemName: icon)
                        .foregroundColor(.textSecondary)
                }

                Group {
                    if isSecure {
                        SecureField(fieldLabel, text: $text, prompt: Text(placeholder).foregroundColor(.textSecondary))
                    } else {
                        TextField(fieldLabel, text: $text, prompt: Text(placeholder).foregroundColor(.textSecondary))
                    }
                }
                .textFieldStyle(.plain)
                .font(.peatedInput)
                .foregroundColor(.text)
                .keyboardType(keyboard)
                .submitLabel(submitLabel)
                .autocorrectionDisabled(!autocorrection)
                .textInputAutocapitalization(capitalization)
                .textContentType(contentType)
                .onSubmit { onSubmit?() }
                .focused(focusBinding)
                // The visible label is a separate Text, so name the field for VoiceOver.
                .accessibilityLabel(fieldLabel)
                .accessibilityIdentifier(identifier ?? "")

                if let unit, !unit.isEmpty {
                    Text(unit)
                        .font(.peatedMetadata)
                        .foregroundColor(.textSecondary)
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
        let focused = isFocused?.wrappedValue ?? internalFocused
        return focused ? .focused : .normal
    }

    private var focusBinding: FocusState<Bool>.Binding {
        isFocused ?? $internalFocused
    }

    private var fieldLabel: String {
        guard let label, !label.isEmpty else {
            return placeholder
        }
        guard requirement == .optional else {
            return label
        }
        return "\(label), optional"
    }
}
