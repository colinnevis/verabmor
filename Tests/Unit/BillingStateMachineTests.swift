import XCTest
@testable import RealLifeLingo

final class BillingStateMachineTests: XCTestCase {
    private var persistence: PersistenceController!
    private var userRepository: UserRepository!
    private var usageRepository: UsageEventRepository!
    private var membershipRepository: MembershipRepository!
    private var orgRepository: OrgRepository!
    private var billing: BillingService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        userRepository = UserRepository(persistence: persistence)
        usageRepository = UsageEventRepository(persistence: persistence)
        membershipRepository = MembershipRepository(persistence: persistence)
        orgRepository = OrgRepository(persistence: persistence)
        billing = BillingService(userRepository: userRepository, usageRepository: usageRepository, membershipRepository: membershipRepository, orgRepository: orgRepository, billingClient: StubBillingClient())
    }

    func testUsagePromotesStorageUser() {
        var user = TestFixtures.user
        user.planTier = .storage
        user.autoReactivate = true
        userRepository.save(user)
        let event = UsageEvent(id: UUID().uuidString, userId: user.id, orgId: nil, type: .transcribe, createdAt: Date(), payloadJSON: "{}")
        billing.process(event: event)
        guard let updated = userRepository.getUser(id: user.id) else { return XCTFail("Missing user") }
        XCTAssertEqual(updated.planTier, .active)
        XCTAssertNotNil(updated.nextBillDate)
    }

    func testNightlyDowngrade() {
        var user = TestFixtures.user
        user.planTier = .active
        user.nextBillDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        user.lastUsageAt = Calendar.current.date(byAdding: .day, value: -40, to: Date())
        userRepository.save(user)
        billing.nightlyDowngrade(currentDate: Date())
        let updated = userRepository.getUser(id: user.id)
        XCTAssertEqual(updated?.planTier, .storage)
    }
}
