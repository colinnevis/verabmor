import Foundation

public protocol UsageEventProcessing {
    func process(event: UsageEvent)
}

public final class BillingService: UsageEventProcessing {
    private let userRepository: UserRepositoryType
    private let usageRepository: UsageEventRepositoryType
    private let membershipRepository: MembershipRepositoryType
    private let orgRepository: OrgRepositoryType
    private let billingClient: BillingClient

    public init(userRepository: UserRepositoryType,
                usageRepository: UsageEventRepositoryType,
                membershipRepository: MembershipRepositoryType,
                orgRepository: OrgRepositoryType,
                billingClient: BillingClient) {
        self.userRepository = userRepository
        self.usageRepository = usageRepository
        self.membershipRepository = membershipRepository
        self.orgRepository = orgRepository
        self.billingClient = billingClient
    }

    public func process(event: UsageEvent) {
        guard var user = userRepository.getUser(id: event.userId) else { return }
        switch event.type {
        case .transcribe, .aiGenerate:
            guard user.autoReactivate || user.planTier != .storage else { return }
            if user.planTier == .storage {
                user.planTier = .active
                user.lastStateChangeAt = event.createdAt
            }
            user.lastUsageAt = event.createdAt
            let nextBill = event.createdAt.addingTimeInterval(60 * 60 * 24 * 30)
            if let existing = user.nextBillDate {
                user.nextBillDate = max(existing, nextBill)
            } else {
                user.nextBillDate = nextBill
            }
            userRepository.save(user)
            billingClient.ensureActiveSubscription(for: user) { _ in }
        case .review:
            if user.planTier == .storage {
                user.lastUsageAt = event.createdAt
                userRepository.save(user)
            }
        }
    }

    public func nightlyDowngrade(currentDate: Date = Date()) {
        let users = userRepository.fetchAll()
        for var user in users {
            guard let nextBill = user.nextBillDate else { continue }
            if currentDate > nextBill {
                if let lastUsage = user.lastUsageAt, currentDate.timeIntervalSince(lastUsage) < 60 * 60 * 24 * 30 {
                    continue
                }
                user.planTier = .storage
                user.lastStateChangeAt = currentDate
                userRepository.save(user)
            }
        }
    }

    public func sendMeteringSnapshot(periodStart: Date) {
        let orgs = orgRepository.fetchAll()
        for org in orgs {
            let memberships = membershipRepository.memberships(forOrg: org.id)
            var activeCount = 0
            for membership in memberships {
                guard let user = userRepository.getUser(id: membership.userId) else { continue }
                let usage = usageRepository.events(for: membership.userId, since: periodStart)
                let hasUsage = usage.contains { $0.type == .transcribe || $0.type == .aiGenerate }
                if user.planTier == .team || hasUsage {
                    activeCount += 1
                }
            }
            guard activeCount > 0 else { continue }
            billingClient.sendMeteredUsage(orgId: org.id, quantity: activeCount, periodStart: periodStart) { _ in }
        }
    }
}
