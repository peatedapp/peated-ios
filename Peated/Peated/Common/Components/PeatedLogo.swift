import SwiftUI

struct PeatedLogo: View {
    let height: CGFloat

    var body: some View {
        // Try to load the image, fall back to text if not available
        if UIImage(named: "PeatedLogo") != nil {
            Image("PeatedLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .foregroundColor(.brand)
        } else {
            // Fallback text logo
            Text("PEATED")
                .font(.custom(PeatedFontName.display, size: height * 0.4))
                .foregroundColor(.brand)
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
    .background(Color.background)
}
