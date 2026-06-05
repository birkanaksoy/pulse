import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(score: Int, personality: Personality, variant: ShareCardView.Variant) -> UIImage? {
        let view = ShareCardView(score: score, personality: personality, variant: variant)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
