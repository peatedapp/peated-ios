import SwiftUI

// Custom TextField with proper placeholder styling
struct PeatedTextField: View {
  let placeholder: String
  @Binding var text: String
  var isSecure: Bool = false
  
  var body: some View {
    ZStack(alignment: .leading) {
      if text.isEmpty {
        Text(placeholder)
          .foregroundColor(.peatedTextMuted)
      }
      
      if isSecure {
        SecureField("", text: $text)
          .foregroundColor(.peatedTextPrimary)
      } else {
        TextField("", text: $text)
          .foregroundColor(.peatedTextPrimary)
      }
    }
    .tint(.peatedGold)
  }
}