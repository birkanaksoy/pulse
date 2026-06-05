import SwiftUI

struct SectionHeader: View {
    var title: LocalizedStringKey
    var trailing: AnyView? = nil

    init(_ title: LocalizedStringKey, trailing: AnyView? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: PulseSpace.s) {
            Capsule()
                .fill(PulseColor.ringGradient)
                .frame(width: 3, height: 18)
            Text(title)
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Spacer()
            if let trailing { trailing }
        }
    }
}
