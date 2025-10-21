import XCTest
@testable import RealLifeLingo

final class CardExtractionTests: XCTestCase {
    private var persistence: PersistenceController!
    private var cardRepository: CardRepository!
    private var usageRepository: UsageEventRepository!
    private var service: CardCreationService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        cardRepository = CardRepository(persistence: persistence)
        usageRepository = UsageEventRepository(persistence: persistence)
        let nlp = AppleNLPService()
        service = CardCreationService(nlpService: nlp, imageClient: StubImageGenClient(), llmClient: StubLLMClient(), dictionaryService: LocalDictionaryService(), cardRepository: cardRepository, usageRepository: usageRepository, eventProcessor: NoopProcessor())
    }

    func testGeneratesMultiWordChunks() async {
        let user = TestFixtures.user
        let source = Source(id: "source", userId: user.id, orgId: nil, type: .transcript, uri: "local://test", language: "es", metaJSON: "{}", firstSeenAt: Date(), lastIngestedAt: Date())
        let transcript = Transcript(id: "tx", sourceId: "source", durationSec: 30, segments: [
            TranscriptSegment(id: UUID(), speaker: "Teacher", text: "Muchas gracias por venir", start: 0, end: 3, isStarred: true),
            TranscriptSegment(id: UUID(), speaker: "You", text: "Quiero aprender más español", start: 4, end: 7, isStarred: false)
        ])
        let cards = await service.generateCards(user: user, source: source, transcript: transcript)
        XCTAssertFalse(cards.isEmpty)
        XCTAssertTrue(cards.contains { $0.l2Text.contains("muchas gracias") || $0.tags.contains("phrase") })
    }
}
