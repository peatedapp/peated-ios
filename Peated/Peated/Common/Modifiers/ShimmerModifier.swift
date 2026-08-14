import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation: Animation
    let gradient: Gradient

    init(
        animation: Animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
        gradient: Gradient = Gradient(colors: [
            Color.border.opacity(0.2),
            Color.border.opacity(0.45),
            Color.border.opacity(0.2)
        ])
    ) {
        self.animation = animation
        self.gradient = gradient
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { _ in
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .init(x: phase - 0.3, y: 0.5),
                        endPoint: .init(x: phase + 0.3, y: 0.5)
                    )
                    .scaleEffect(x: 3, y: 1)
                    .onAppear {
                        withAnimation(animation) {
                            phase = 1.3
                        }
                    }
                }
                .mask(content)
            )
    }
}

extension View {
    func shimmer(
        animation: Animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
        gradient: Gradient = Gradient(colors: [
            Color.border.opacity(0.2),
            Color.border.opacity(0.45),
            Color.border.opacity(0.2)
        ])
    ) -> some View {
        modifier(ShimmerModifier(animation: animation, gradient: gradient))
    }
}
