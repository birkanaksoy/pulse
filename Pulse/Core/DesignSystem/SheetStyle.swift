import SwiftUI

extension View {
    /// Consistent presentation style for Pulse sheets: drag indicator, 28pt corner,
    /// background tied to canvas so dark mode looks intentional.
    func pulseSheet(detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(PulseColor.canvas)
    }
}
