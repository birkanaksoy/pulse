import UIKit
import CoreGraphics

/// 64-bit average-hash perceptual fingerprint. Hamming distance ≤ 5 is "very
/// similar" — strong enough for detecting near-duplicate photos (bursts,
/// re-takes), tolerant of small crops and recompression.
enum PerceptualHash {
    static func aHash(_ image: UIImage) -> UInt64? {
        guard let cg = image.cgImage else { return nil }

        // 8×8 grayscale buffer.
        let w = 8, h = 8
        var bytes = [UInt8](repeating: 0, count: w * h)
        let cs = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: &bytes,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        let avg = bytes.reduce(0) { $0 + Int($1) } / bytes.count
        var hash: UInt64 = 0
        for (i, b) in bytes.enumerated() where Int(b) >= avg {
            hash |= (1 << UInt64(63 - i))
        }
        return hash
    }

    static func hamming(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }
}
