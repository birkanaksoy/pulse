import Foundation
import Photos
import Observation

/// One-tap parallel analysis: finds duplicates, bursts, big videos, and
/// Live Photos all at once. Returns a single combined plan so the user
/// confirms once per category and sees the running freed-byte total.
@Observable
@MainActor
final class MagicCleanup {

    enum Phase: Equatable {
        case idle
        case analyzing(progress: Double, stage: String)
        case ready(plan: Plan)
        case cleaning(progress: Double, stage: String, freedSoFar: Int64)
        case done(freed: Int64)
    }

    struct Plan: Equatable {
        var duplicates: [PHAsset]     // all extras (best kept)
        var bursts: [PHAsset]          // all extras
        var largeVideos: [PHAsset]     // sorted desc, top 10
        var livePhotos: [PHAsset]      // for conversion

        var deleteBytes: Int64 { 0 }
        var totalSavings: Int64 { deletableBytes + convertibleBytes }
        var deletableBytes: Int64 {
            (duplicates + bursts + largeVideos).reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) }
        }
        var convertibleBytes: Int64 {
            livePhotos.reduce(into: Int64(0)) { $0 += Int64(Double(PhotoCleaner.bytes(of: $1)) * 0.6) }
        }
        var deletableCount: Int { duplicates.count + bursts.count + largeVideos.count }
        var convertibleCount: Int { livePhotos.count }
        var isEmpty: Bool { deletableCount == 0 && convertibleCount == 0 }
    }

    var phase: Phase = .idle

    private let duplicatesEngine = DuplicateDetector()
    private let burstsEngine     = BurstDetector()
    private let videosEngine     = LargeVideoFinder()
    private let liveEngine       = LivePhotoConverter()

    func analyze() async {
        phase = .analyzing(progress: 0.0, stage: String(localized: "Looking for duplicates…"))
        await duplicatesEngine.scan()

        phase = .analyzing(progress: 0.40, stage: String(localized: "Grouping bursts…"))
        await burstsEngine.scan()

        phase = .analyzing(progress: 0.70, stage: String(localized: "Finding big videos…"))
        await videosEngine.scan()

        phase = .analyzing(progress: 0.90, stage: String(localized: "Detecting Live Photos…"))
        await liveEngine.scan()

        let plan = Plan(
            duplicates: duplicatesEngine.groups.flatMap { Array($0.assets.dropFirst()) },
            bursts:     burstsEngine.groups.flatMap { Array($0.assets.dropFirst()) },
            // Take top 10 videos over 100 MB so the suggestion isn't overwhelming.
            largeVideos: videosEngine.videos
                .filter { $0.bytes > 100 * 1024 * 1024 }
                .prefix(10).map(\.asset),
            livePhotos: liveEngine.entries.map(\.asset)
        )
        phase = .ready(plan: plan)
    }

    func execute(plan: Plan) async {
        var freed: Int64 = 0
        phase = .cleaning(progress: 0.0, stage: String(localized: "Removing duplicates…"), freedSoFar: 0)

        if !plan.duplicates.isEmpty {
            let r = await PhotoCleaner.delete(plan.duplicates)
            if r.success { freed += r.freed }
        }

        phase = .cleaning(progress: 0.30, stage: String(localized: "Removing extra burst shots…"), freedSoFar: freed)

        if !plan.bursts.isEmpty {
            let r = await PhotoCleaner.delete(plan.bursts)
            if r.success { freed += r.freed }
        }

        phase = .cleaning(progress: 0.60, stage: String(localized: "Removing big videos…"), freedSoFar: freed)

        if !plan.largeVideos.isEmpty {
            let r = await PhotoCleaner.delete(plan.largeVideos)
            if r.success { freed += r.freed }
        }

        phase = .cleaning(progress: 0.85, stage: String(localized: "Converting Live Photos…"), freedSoFar: freed)

        if !plan.livePhotos.isEmpty {
            let entries = plan.livePhotos.map { LivePhotoEntry(id: $0.localIdentifier, asset: $0, bytes: PhotoCleaner.bytes(of: $0)) }
            let convertedBytes = await liveEngine.convert(entries)
            freed += convertedBytes
        }

        phase = .done(freed: freed)
    }

    func reset() { phase = .idle }
}
