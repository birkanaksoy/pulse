import Foundation

struct StorageReading: Equatable {
    var totalBytes: Int64
    var freeBytes: Int64
    var usedPercent: Int { // 0–100
        guard totalBytes > 0 else { return 0 }
        let used = Double(totalBytes - freeBytes) / Double(totalBytes)
        return Int((used * 100).rounded())
    }
}

struct StorageProbe {
    func read() -> StorageReading {
        let url = URL(fileURLWithPath: NSHomeDirectory() as String)
        // We deliberately use `volumeAvailableCapacityKey` (raw filesystem
        // free space) rather than `…ForImportantUsageKey`. The "Important"
        // value counts purgeable cache as available, which makes Pulse show
        // LESS used than what Settings → iPhone Storage shows. Users compare
        // to Settings, so we match that view.
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey
        ]
        let values = try? url.resourceValues(forKeys: keys)
        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let free  = Int64(values?.volumeAvailableCapacity ?? 0)
        return StorageReading(totalBytes: total, freeBytes: free)
    }
}
