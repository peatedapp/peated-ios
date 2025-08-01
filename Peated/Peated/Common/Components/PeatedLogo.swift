import SwiftUI

struct PeatedLogo: View {
  let height: CGFloat
  
  var body: some View {
    // Try to load the image, fall back to text if not available
    if UIImage(named: "PeatedLogo") != nil {
      Image("PeatedLogo")
        .renderingMode(.template)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: height)
        .foregroundColor(.peatedGold)
    } else {
      // Fallback text logo
      Text("PEATED")
        .font(.system(size: height * 0.4, weight: .black, design: .default))
        .foregroundColor(.peatedGold)
        .tracking(height * 0.08)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    PeatedLogo(height: 40)
    PeatedLogo(height: 60)
    PeatedLogo(height: 80)
  }
  .padding()
  .background(Color.peatedBackground)
}