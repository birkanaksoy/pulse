import SwiftUI

/// The Pulse app icon, clipped to iOS's standard rounded-square shape.
/// Used in launch animation, onboarding glyphs, and anywhere we want
/// the actual brand mark inline.
struct PulseLogo: View {
    var size: CGFloat = 100
    var shadow: Bool = true

    var body: some View {
        Image("BrandLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .strokeBorder(PulseColor.stroke, lineWidth: 0.5)
            )
            .shadow(color: shadow ? .black.opacity(0.12) : .clear,
                    radius: size * 0.10, y: size * 0.04)
    }
}

#Preview {
    VStack(spacing: 24) {
        PulseLogo(size: 140)
        PulseLogo(size: 80)
        PulseLogo(size: 44, shadow: false)
    }
    .padding()
    .background(PulseColor.muted)
}
