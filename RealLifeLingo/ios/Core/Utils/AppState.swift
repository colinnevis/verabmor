import Foundation

public final class AppState: ObservableObject {
    @Published public var currentUser: UserProfile
    @Published public var memberships: [Membership]

    private let userRepository: UserRepositoryType
    private let membershipRepository: MembershipRepositoryType

    public init(environment: AppEnvironment) {
        self.userRepository = environment.userRepository
        self.membershipRepository = environment.membershipRepository
        if let existing = environment.userRepository.fetchAll().first {
            currentUser = existing
        } else {
            let user = UserProfile(
                id: UUID().uuidString,
                email: "demo@reallifelingo.app",
                displayName: "Demo Learner",
                planTier: .active,
                lastUsageAt: Date(),
                nextBillDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                lastBilledAt: Date(),
                orgIds: [],
                lastStateChangeAt: Date(),
                cloudAIEnabled: true,
                autoReactivate: true,
                goalDailyNew: 20,
                hobbies: "Travel, food",
                l1: "en",
                l2: "es",
                proficiency: "B1",
                timePerDay: "30",
                voicePreference: "Neutral",
                nsfwFilter: true
            )
            environment.userRepository.save(user)
            currentUser = user
        }
        memberships = membershipRepository.memberships(for: currentUser.id)
    }

    public func refreshMemberships() {
        memberships = membershipRepository.memberships(for: currentUser.id)
    }
}
