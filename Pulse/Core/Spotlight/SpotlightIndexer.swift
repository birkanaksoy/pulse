import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

/// Mirrors the latest scan into Spotlight so the user can search "Pulse score"
/// in Spotlight and see the live number — then tap to open the app.
enum SpotlightIndexer {
    static let lastScanID = "pulse.spotlight.lastScan"

    static func indexLatest(score: Int, status: String, at date: Date) {
        let attrs = CSSearchableItemAttributeSet(contentType: UTType.text)
        attrs.title = "Pulse · \(score)"
        attrs.contentDescription = "\(status) — \(date.formatted(.relative(presentation: .named)))"
        attrs.keywords = ["pulse", "phone health", "score", "battery", "storage"]

        let item = CSSearchableItem(
            uniqueIdentifier: lastScanID,
            domainIdentifier: "app.pulse.scan",
            attributeSet: attrs
        )
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 14, to: date)
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    static func clear() {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [lastScanID])
    }
}
