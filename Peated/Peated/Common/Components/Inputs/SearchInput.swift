import SwiftUI

// MARK: - SearchInput

/// Reusable search field with leading icon and trailing clear button, styled via InputBox.
struct SearchInput: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding?
    var onSubmit: (() -> Void)?
    /// Stable identifier for UI tests. See `AccessibilityID`.
    var identifier: String?
    @FocusState private var internalFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.textSecondary)
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textSecondary))
                .textFieldStyle(.plain)
                .font(.peatedInput)
                .foregroundColor(.text)
                .focused(focusBinding)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
                .accessibilityIdentifier(identifier ?? "")
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // Keep a 44pt target without making the field taller.
                .padding(.vertical, -12)
                .padding(.trailing, -12)
                .accessibilityLabel("Clear search")
            }
        }
        .inputBox(state: focused ? .focused : .normal)
    }

    private var focused: Bool {
        isFocused?.wrappedValue ?? internalFocused
    }

    private var focusBinding: FocusState<Bool>.Binding {
        isFocused ?? $internalFocused
    }
}
