import SwiftUI

struct SectionHeader: View {
    var title: LocalizedStringKey
    var trailing: AnyView? = nil

    init(_ title: LocalizedStringKey, trailing: AnyView? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: PulseSpace.m) {
            ZStack {
                Capsule()
                    .fill(PulseColor.ringGradient)
                    .frame(width: 4, height: 22)
                Capsule()
                    .fill(.white.opacity(0.35))
                    .frame(width: 4, height: 10)
                    .offset(y: -6)
            }
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundStyle(PulseColor.textPrimary)
                .kerning(-0.3)
            Spacer()
            if let trailing { trailing }
        }
    }
}
