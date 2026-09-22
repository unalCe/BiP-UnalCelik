import SwiftUI


struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay {
                    GeometryReader { proxy in
                        let band = proxy.size.width * 0.35
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.38), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: band)
                        .offset(x: -band + phase * (proxy.size.width + band))
                    }
                }
                .mask(content)
                .onAppear {
                    withAnimation(
                        .linear(duration: Skeleton.sweepDuration).repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        }
    }
}

public extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
