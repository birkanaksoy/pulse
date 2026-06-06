import Foundation

enum CSVExporter {
    /// Returns CSV bytes ready to write to disk or share.
    static func data(from records: [ScanRecord]) -> Data {
        var lines: [String] = []
        lines.append("timestamp,pulse_score,storage_used_pct,thermal_raw,battery_level,battery_state,low_power_mode")
        let iso = ISO8601DateFormatter()
        for r in records.sorted(by: { $0.timestamp < $1.timestamp }) {
            let ts = iso.string(from: r.timestamp)
            let b  = r.batteryLevel.map(String.init) ?? ""
            let bs = r.batteryStateRaw.map(String.init) ?? ""
            let lp = r.lowPowerMode.map { $0 ? "1" : "0" } ?? ""
            lines.append("\(ts),\(r.pulseScore),\(r.storageUsed),\(r.thermalRaw),\(b),\(bs),\(lp)")
        }
        return (lines.joined(separator: "\n") + "\n").data(using: .utf8) ?? Data()
    }

    /// Writes to a temporary file and returns its URL.
    static func writeToTemp(_ records: [ScanRecord]) throws -> URL {
        let data = data(from: records)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pulse-history.csv")
        try data.write(to: url, options: .atomic)
        return url
    }
}
