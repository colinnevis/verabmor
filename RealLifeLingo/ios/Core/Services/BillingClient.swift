import Foundation

public protocol BillingClient {
    func ensureActiveSubscription(for user: UserProfile, completion: @escaping (Result<Void, Error>) -> Void)
    func sendMeteredUsage(orgId: String, quantity: Int, periodStart: Date, completion: @escaping (Result<Void, Error>) -> Void)
}

public final class StubBillingClient: BillingClient {
    public init() {}

    public func ensureActiveSubscription(for user: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    public func sendMeteredUsage(orgId: String, quantity: Int, periodStart: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
