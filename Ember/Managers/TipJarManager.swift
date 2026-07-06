import StoreKit

/// Handles tip jar in-app purchases. Configure the product in App Store
/// Connect: create a consumable IAP named "com.ryantdo.Ember.coffee" priced
/// at $0.99 in all regions. This manager fetches and processes the purchase.
actor TipJarManager {
    static let shared = TipJarManager()

    private let productID = "com.ryantdo.Ember.coffee"
    private var product: Product?

    func fetchProduct() async -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            self.product = products.first
            return self.product
        } catch {
            return nil
        }
    }

    func purchase() async -> Bool {
        guard let product = product ?? (try? await Product.products(for: [productID]).first) else {
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }
}
