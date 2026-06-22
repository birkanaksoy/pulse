import Foundation
import Photos
import Observation

@Observable
@MainActor
final class SwipeSession {
    enum Decision { case delete, keep }

    var assets: [PHAsset] = []
    var currentIndex: Int = 0
    var marked: [PHAsset] = []     // marked for delete
    var kept: [PHAsset] = []
    var history: [Decision] = []   // for undo

    var currentAsset: PHAsset? {
        guard currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }

    /// Lookahead for the second card in the stack.
    var nextAsset: PHAsset? {
        let next = currentIndex + 1
        guard next < assets.count else { return nil }
        return assets[next]
    }

    var isFinished: Bool { currentIndex >= assets.count }
    var progress: Double {
        guard !assets.isEmpty else { return 0 }
        return Double(currentIndex) / Double(assets.count)
    }

    /// Bytes the user is about to free if they confirm.
    var pendingBytes: Int64 {
        marked.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) }
    }

    // MARK: - Actions

    func load(_ assets: [PHAsset]) {
        self.assets = assets
        currentIndex = 0
        marked = []
        kept = []
        history = []
    }

    func decide(_ d: Decision) {
        guard let asset = currentAsset else { return }
        switch d {
        case .delete: marked.append(asset)
        case .keep:
            kept.append(asset)
            // Persist immediately so we don't re-show this photo next session.
            PhotoMemory.recordKept([asset.localIdentifier])
        }
        history.append(d)
        currentIndex += 1
    }

    /// Pops the last decision off and steps the cursor back.
    func undo() {
        guard let last = history.popLast(), currentIndex > 0 else { return }
        currentIndex -= 1
        switch last {
        case .delete: _ = marked.popLast()
        case .keep:   _ = kept.popLast()
        }
    }
}
