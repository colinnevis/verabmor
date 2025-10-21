import Foundation

public final class AppEnvironment: ObservableObject {
    public let persistence: PersistenceController
    public let userRepository: UserRepositoryType
    public let orgRepository: OrgRepositoryType
    public let membershipRepository: MembershipRepositoryType
    public let sourceRepository: SourceRepositoryType
    public let transcriptRepository: TranscriptRepositoryType
    public let cardRepository: CardRepositoryType
    public let reviewRepository: ReviewRepositoryType
    public let usageRepository: UsageEventRepositoryType
    public let weeklyUsageRepository: WeeklyUsageRepositoryType
    public let transcriptionService: TranscriptionService
    public let nlpService: NLPService
    public let cardCreationService: CardCreationService
    public let ingestionService: IngestionService
    public let srsService: SRSService
    public let billingService: BillingService
    public let analyticsService: AnalyticsService

    public init(persistence: PersistenceController = .shared,
                userRepository: UserRepositoryType? = nil,
                orgRepository: OrgRepositoryType? = nil,
                membershipRepository: MembershipRepositoryType? = nil,
                sourceRepository: SourceRepositoryType? = nil,
                transcriptRepository: TranscriptRepositoryType? = nil,
                cardRepository: CardRepositoryType? = nil,
                reviewRepository: ReviewRepositoryType? = nil,
                usageRepository: UsageEventRepositoryType? = nil,
                weeklyUsageRepository: WeeklyUsageRepositoryType? = nil,
                transcriptionService: TranscriptionService? = nil,
                nlpService: NLPService? = nil,
                cardCreationService: CardCreationService? = nil,
                ingestionService: IngestionService? = nil,
                srsService: SRSService? = nil,
                billingService: BillingService? = nil,
                analyticsService: AnalyticsService? = nil) {
        self.persistence = persistence
        self.userRepository = userRepository ?? UserRepository(persistence: persistence)
        self.orgRepository = orgRepository ?? OrgRepository(persistence: persistence)
        self.membershipRepository = membershipRepository ?? MembershipRepository(persistence: persistence)
        self.sourceRepository = sourceRepository ?? SourceRepository(persistence: persistence)
        self.transcriptRepository = transcriptRepository ?? TranscriptRepository(persistence: persistence)
        self.cardRepository = cardRepository ?? CardRepository(persistence: persistence)
        self.reviewRepository = reviewRepository ?? ReviewRepository(persistence: persistence)
        self.usageRepository = usageRepository ?? UsageEventRepository(persistence: persistence)
        self.weeklyUsageRepository = weeklyUsageRepository ?? WeeklyUsageRepository(persistence: persistence)

        let imageClient = StubImageGenClient()
        let llmClient = StubLLMClient()
        let nlpService = nlpService ?? AppleNLPService()
        self.nlpService = nlpService
        self.transcriptionService = transcriptionService ?? AppleSpeechTranscriptionService(nlpService: nlpService)
        let dictionaryService = LocalDictionaryService()
        let billingClient = StubBillingClient()
        let billingServiceInstance = billingService ?? BillingService(userRepository: self.userRepository, usageRepository: self.usageRepository, membershipRepository: self.membershipRepository, orgRepository: self.orgRepository, billingClient: billingClient)
        self.billingService = billingServiceInstance
        self.cardCreationService = cardCreationService ?? CardCreationService(
            nlpService: nlpService,
            imageClient: imageClient,
            llmClient: llmClient,
            dictionaryService: dictionaryService,
            cardRepository: self.cardRepository,
            usageRepository: self.usageRepository,
            eventProcessor: billingServiceInstance
        )
        self.ingestionService = ingestionService ?? IngestionService(
            sourceRepository: self.sourceRepository,
            transcriptRepository: self.transcriptRepository,
            cardCreationService: self.cardCreationService,
            nlpService: self.nlpService,
            usageRepository: self.usageRepository,
            eventProcessor: billingServiceInstance
        )
        self.srsService = srsService ?? SRSService(cardRepository: self.cardRepository, reviewRepository: self.reviewRepository, usageRepository: self.usageRepository, eventProcessor: billingServiceInstance)
        self.analyticsService = analyticsService ?? AnalyticsService(usageRepository: self.usageRepository, weeklyUsageRepository: self.weeklyUsageRepository, cardRepository: self.cardRepository, reviewRepository: self.reviewRepository, sourceRepository: self.sourceRepository, membershipRepository: self.membershipRepository, orgRepository: self.orgRepository, userRepository: self.userRepository)

        let seedLoader = SeedLoader(
            persistence: self.persistence,
            userRepository: self.userRepository,
            orgRepository: self.orgRepository,
            membershipRepository: self.membershipRepository,
            sourceRepository: self.sourceRepository,
            transcriptRepository: self.transcriptRepository,
            cardRepository: self.cardRepository,
            reviewRepository: self.reviewRepository,
            usageRepository: self.usageRepository,
            weeklyUsageRepository: self.weeklyUsageRepository,
            eventProcessor: billingServiceInstance
        )
        seedLoader.bootstrapIfNeeded()
    }
}
