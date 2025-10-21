import XCTest
@testable import RealLifeLingo

final class SRSSchedulerTests: XCTestCase {
    private var persistence: PersistenceController!
    private var cardRepository: CardRepository!
    private var reviewRepository: ReviewRepository!
    private var usageRepository: UsageEventRepository!
    private var scheduler: SRSService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        cardRepository = CardRepository(persistence: persistence)
        reviewRepository = ReviewRepository(persistence: persistence)
        usageRepository = UsageEventRepository(persistence: persistence)
        scheduler = SRSService(cardRepository: cardRepository, reviewRepository: reviewRepository, usageRepository: usageRepository, eventProcessor: NoopProcessor())
    }

    func testPerfectReviewAdvancesInterval() {
        var card = Card(id: "card", userId: "user", sourceType: .transcript, sourceId: "source", sourceLoc: "0", l1Text: "hello", l2Text: "hola", gloss: "hello", pos: "noun", cefr: "A2", imageURL: "", audioURL: nil, exampleL2: "Hola", exampleL1: "Hello", tags: [], createdAt: Date(), strength: 0, ease: 2.5, nextDueAt: nil)
        cardRepository.save(card)
        let user = TestFixtures.user
        card = scheduler.grade(card: card, grade: 5, user: user, device: "test")
        XCTAssertEqual(card.strength, 1)
        XCTAssertNotNil(card.nextDueAt)
        let firstDue = card.nextDueAt!
        card = scheduler.grade(card: card, grade: 5, user: user, device: "test")
        XCTAssertEqual(card.strength, 2)
        XCTAssertTrue(card.nextDueAt! > firstDue)
    }

    func testFailureResetsInterval() {
        var card = Card(id: "card", userId: "user", sourceType: .transcript, sourceId: "source", sourceLoc: "0", l1Text: "hello", l2Text: "hola", gloss: "hello", pos: "noun", cefr: "A2", imageURL: "", audioURL: nil, exampleL2: "Hola", exampleL1: "Hello", tags: [], createdAt: Date(), strength: 0, ease: 2.5, nextDueAt: nil)
        cardRepository.save(card)
        let user = TestFixtures.user
        card = scheduler.grade(card: card, grade: 2, user: user, device: "test")
        XCTAssertEqual(card.strength, 0)
        XCTAssertEqual(card.ease, 2.3)
    }
}
