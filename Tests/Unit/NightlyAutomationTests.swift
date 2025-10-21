import XCTest
@testable import RealLifeLingo

final class NightlyAutomationTests: XCTestCase {
    func testNightlyRoutinesExecuteWithoutError() {
        let persistence = PersistenceController(inMemory: true)
        let environment = AppEnvironment(persistence: persistence)

        var user = TestFixtures.user
        user.planTier = .active
        user.nextBillDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        user.lastUsageAt = Calendar.current.date(byAdding: .day, value: -40, to: Date())
        environment.userRepository.save(user)

        environment.analyticsService.nightlyRollup(date: Date())
        environment.billingService.nightlyDowngrade(currentDate: Date())

        let updated = environment.userRepository.getUser(id: user.id)
        XCTAssertEqual(updated?.planTier, .storage)
    }
}
