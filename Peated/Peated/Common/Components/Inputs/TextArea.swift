import SwiftUI

// MARK: - TextArea
// Reusable multi-line input with placeholder, theming, and focus/error handling.
struct TextArea: View {
  let label: String?
  let placeholder: String
  @Binding var text: String
  var minHeight: CGFloat = 100
  var disabled: Bool = false
  var error: String? = nil
  var helper: String? = nil

  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let label = label, !label.isEmpty {
        Text(label)
          .font(.caption)
          .foregroundColor(.textSecondary)
      }

      ZStack(alignment: .topLeading) {
        TextEditor(text: $text)
          .frame(minHeight: minHeight)
          .foregroundColor(.text)
          .background(Color.clear)
          .focused($isFocused)

        if text.isEmpty && !isFocused {
          Text(placeholder)
            .foregroundColor(.textMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
      }
      .inputBox(state: inputState)
      .disabled(disabled)

      if let error = error, !error.isEmpty {
        Text(error)
          .font(.caption)
          .foregroundColor(.danger)
      } else if let helper = helper, !helper.isEmpty {
        Text(helper)
          .font(.caption)
          .foregroundColor(.textSecondary)
      }
    }
  }

  private var inputState: InputBox.State {
    if disabled { return .disabled }
    if error != nil { return .error }
    return isFocused ? .focused : .normal
  }
}
