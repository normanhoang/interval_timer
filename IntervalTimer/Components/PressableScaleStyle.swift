import SwiftUI

/// Button style that springs to 0.97 while pressed (replaces RN PressableScale).
struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleStyle {
    static var pressableScale: PressableScaleStyle { PressableScaleStyle() }
}
