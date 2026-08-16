import SwiftUI

// MARK: - SearchInput

/// Reusable search field with leading icon and trailing clear button, styled via InputBox.
struct SearchInput: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding?
    var onSubmit: (() -> Void)?
    @FocusState private var internalFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.textSecondary)
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                .textFieldStyle(.plain)
                .foregroundColor(.text)
                .focused(focusBinding)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
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
