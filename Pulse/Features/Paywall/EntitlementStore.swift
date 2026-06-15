import Foundation
import StoreKit
import Observation
import WidgetKit

@Observable
@MainActor
final class EntitlementStore {
    var isPro: Bool = false
    var products: [Product] = []
    var purchaseInFlight = false

    /// Configure these IDs in App Store Connect (and Pulse.storekit for local dev).
    static let productIDs: Set<String> = [
        "com.birkan.pulse.pro.weekly",
        "com.birkan.pulse.pro.monthly",
        "com.birkan.pulse.lifetime"
    ]

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForUpdates() }
        Task { await refresh() }
    }


    func refresh() async {
        do {
            products = try await Product.products(for: Self.productIDs)
        } catch {
            products = []
        }
        await updateEntitlements()
    }

    func purchase(_ product: Product) async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await updateEntitlements()
                }
            default:
                break
            }
        } catch {
            // Surface in UI later; non-fatal.
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await updateEntitlements()
    }

    private func updateEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, Self.productIDs.contains(tx.productID) {
                unlocked = true
            }
        }
        isPro = unlocked
        // Refresh widget so it can lock/unlock immediately after a purchase.
        if var snap = SharedScoreStore.load() {
            snap.isPro = unlocked
            SharedScoreStore.save(snap)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func listenForUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result {
                await tx.finish()
                await updateEntitlements()
            }
        }
    }

    // MARK: - Dev helpers

    /// Toggle Pro locally without StoreKit — useful before products are configured.
    func devTogglePro() {
        isPro.toggle()
        if var snap = SharedScoreStore.load() {
            snap.isPro = isPro
            SharedScoreStore.save(snap)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
