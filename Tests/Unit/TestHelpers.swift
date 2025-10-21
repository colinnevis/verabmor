import Foundation
@testable import RealLifeLingo

enum TestFixtures {
    static var user: UserProfile {
        UserProfile(id: "user", email: "user@example.com", displayName: "User", planTier: .active, lastUsageAt: nil, nextBillDate: nil, lastBilledAt: nil, orgIds: [], lastStateChangeAt: nil, cloudAIEnabled: true, autoReactivate: true, goalDailyNew: 20, hobbies: "", l1: "en", l2: "es", proficiency: "B1", timePerDay: "30", voicePreference: "", nsfwFilter: true)
    }
}

struct NoopProcessor: UsageEventProcessing {
    func process(event: UsageEvent) {}
}
