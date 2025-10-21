import Foundation
import CoreData

final class SeedLoader {
    private let persistence: PersistenceController
    private let userRepository: UserRepositoryType
    private let orgRepository: OrgRepositoryType
    private let membershipRepository: MembershipRepositoryType
    private let sourceRepository: SourceRepositoryType
    private let transcriptRepository: TranscriptRepositoryType
    private let cardRepository: CardRepositoryType
    private let reviewRepository: ReviewRepositoryType
    private let usageRepository: UsageEventRepositoryType
    private let weeklyUsageRepository: WeeklyUsageRepositoryType
    private let eventProcessor: UsageEventProcessing?
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(persistence: PersistenceController,
         userRepository: UserRepositoryType,
         orgRepository: OrgRepositoryType,
         membershipRepository: MembershipRepositoryType,
         sourceRepository: SourceRepositoryType,
         transcriptRepository: TranscriptRepositoryType,
         cardRepository: CardRepositoryType,
         reviewRepository: ReviewRepositoryType,
         usageRepository: UsageEventRepositoryType,
         weeklyUsageRepository: WeeklyUsageRepositoryType,
         eventProcessor: UsageEventProcessing?) {
        self.persistence = persistence
        self.userRepository = userRepository
        self.orgRepository = orgRepository
        self.membershipRepository = membershipRepository
        self.sourceRepository = sourceRepository
        self.transcriptRepository = transcriptRepository
        self.cardRepository = cardRepository
        self.reviewRepository = reviewRepository
        self.usageRepository = usageRepository
        self.weeklyUsageRepository = weeklyUsageRepository
        self.eventProcessor = eventProcessor
    }

    func bootstrapIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "SeedDataImported") else { return }
        if let storeType = persistence.container.persistentStoreCoordinator.persistentStores.first?.type,
           storeType == NSInMemoryStoreType {
            return
        }
        guard userRepository.fetchAll().isEmpty else {
            UserDefaults.standard.set(true, forKey: "SeedDataImported")
            return
        }
        guard let url = seedFileURL(), let data = try? Data(contentsOf: url) else { return }
        do {
            let decoder = JSONDecoder()
            let payload = try decoder.decode(SeedPayload.self, from: data)
            importUsers(payload.users)
            importOrgs(payload.orgs)
            importMemberships(payload.memberships)
            importSources(payload.sources)
            importTranscripts(payload.transcripts)
            importCards(payload.cards)
            importReviews(payload.reviews)
            importUsageEvents(payload.usageEvents)
            importWeeklyUsage(payload.weeklyUsage)
            UserDefaults.standard.set(true, forKey: "SeedDataImported")
        } catch {
            print("Seed bootstrap failed: \(error)")
        }
    }

    private func seedFileURL() -> URL? {
        if let url = Bundle.main.url(forResource: "seed_state", withExtension: "json", subdirectory: "Seed") {
            return url
        }
        return Bundle(for: SeedLoader.self).url(forResource: "seed_state", withExtension: "json", subdirectory: "Seed")
    }

    private func importUsers(_ users: [SeedUser]) {
        for user in users {
            let profile = UserProfile(
                id: user.userId,
                email: user.email,
                displayName: user.displayName,
                planTier: PlanTier(rawValue: user.planTier) ?? .active,
                lastUsageAt: date(user.lastUsageAt),
                nextBillDate: date(user.nextBillDate),
                lastBilledAt: date(user.lastBilledAt),
                orgIds: user.orgIds,
                lastStateChangeAt: date(user.lastStateChangeAt),
                cloudAIEnabled: user.cloudAIEnabled,
                autoReactivate: user.autoReactivate,
                goalDailyNew: user.goalDailyNew,
                hobbies: user.hobbies,
                l1: user.l1,
                l2: user.l2,
                proficiency: user.proficiency,
                timePerDay: user.timePerDay,
                voicePreference: user.voicePreference,
                nsfwFilter: user.nsfwFilter
            )
            userRepository.save(profile)
        }
    }

    private func importOrgs(_ orgs: [SeedOrg]) {
        for org in orgs {
            let model = Org(id: org.orgId, name: org.name, billingEmail: org.billingEmail, createdAt: date(org.createdAt) ?? Date())
            orgRepository.save(model)
        }
    }

    private func importMemberships(_ memberships: [SeedMembership]) {
        for membership in memberships {
            let model = Membership(orgId: membership.orgId, userId: membership.userId, role: MembershipRole(rawValue: membership.role) ?? .member)
            self.membershipRepository.save(model)
        }
    }

    private func importSources(_ sources: [SeedSource]) {
        for source in sources {
            let model = Source(
                id: source.sourceId,
                userId: source.userId,
                orgId: source.orgId,
                type: SourceType(rawValue: source.type) ?? .transcript,
                uri: source.uri,
                language: source.language,
                metaJSON: source.metaJSON,
                firstSeenAt: date(source.firstSeenAt) ?? Date(),
                lastIngestedAt: date(source.lastIngestedAt)
            )
            sourceRepository.save(model)
        }
    }

    private func importTranscripts(_ transcripts: [SeedTranscript]) {
        for transcript in transcripts {
            let segments = transcript.segments.map { segment in
                TranscriptSegment(
                    id: UUID(),
                    speaker: segment.speaker,
                    text: segment.text,
                    start: segment.start,
                    end: segment.end,
                    isStarred: segment.isStarred
                )
            }
            let model = Transcript(
                id: transcript.transcriptId,
                sourceId: transcript.sourceId,
                durationSec: transcript.durationSec,
                segments: segments
            )
            transcriptRepository.save(model)
        }
    }

    private func importCards(_ cards: [SeedCard]) {
        for card in cards {
            let model = Card(
                id: card.cardId,
                userId: card.userId,
                sourceType: SourceType(rawValue: card.sourceType ?? "transcript"),
                sourceId: card.sourceId,
                sourceLoc: card.sourceLoc,
                l1Text: card.l1Text,
                l2Text: card.l2Text,
                gloss: card.gloss,
                pos: card.pos,
                cefr: card.cefr,
                imageURL: card.imageURL,
                audioURL: card.audioURL,
                exampleL2: card.exampleL2,
                exampleL1: card.exampleL1,
                tags: card.tags,
                createdAt: date(card.createdAt) ?? Date(),
                strength: card.strength,
                ease: card.ease,
                nextDueAt: date(card.nextDueAt)
            )
            cardRepository.save(model)
        }
    }

    private func importReviews(_ reviews: [SeedReview]) {
        for review in reviews {
            let model = Review(
                id: review.reviewId,
                cardId: review.cardId,
                userId: review.userId,
                dueAt: date(review.dueAt),
                shownAt: date(review.shownAt) ?? Date(),
                grade: review.grade,
                ease: review.ease,
                intervalDays: review.intervalDays,
                nextDueAt: date(review.nextDueAt) ?? Date(),
                device: review.device
            )
            reviewRepository.save(model)
        }
    }

    private func importUsageEvents(_ events: [SeedUsageEvent]) {
        for event in events {
            let model = UsageEvent(
                id: event.eventId,
                userId: event.userId,
                orgId: event.orgId,
                type: UsageEventType(rawValue: event.type) ?? .review,
                createdAt: date(event.createdAt) ?? Date(),
                payloadJSON: event.payloadJSON
            )
            usageRepository.save(model)
            eventProcessor?.process(event: model)
        }
    }

    private func importWeeklyUsage(_ usages: [SeedWeeklyUsage]) {
        for usage in usages {
            let model = WeeklyUsage(
                orgId: usage.orgId,
                userId: usage.userId,
                weekStart: date(usage.weekStart) ?? Date(),
                transcripts: usage.transcripts,
                cardsReviewed: usage.cardsReviewed,
                newCards: usage.newCards,
                activeMinutes: usage.activeMinutes,
                lastActivityAt: date(usage.lastActivityAt)
            )
            weeklyUsageRepository.save(model)
        }
    }

    private func date(_ string: String?) -> Date? {
        guard let string else { return nil }
        if let date = isoFormatter.date(from: string) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: string)
    }
}

private struct SeedPayload: Decodable {
    let users: [SeedUser]
    let orgs: [SeedOrg]
    let memberships: [SeedMembership]
    let sources: [SeedSource]
    let transcripts: [SeedTranscript]
    let cards: [SeedCard]
    let reviews: [SeedReview]
    let usageEvents: [SeedUsageEvent]
    let weeklyUsage: [SeedWeeklyUsage]
}

private struct SeedUser: Decodable {
    let userId: String
    let email: String
    let displayName: String
    let planTier: String
    let lastUsageAt: String?
    let nextBillDate: String?
    let lastBilledAt: String?
    let orgIds: [String]
    let lastStateChangeAt: String?
    let cloudAIEnabled: Bool
    let autoReactivate: Bool
    let goalDailyNew: Int
    let hobbies: String
    let l1: String
    let l2: String
    let proficiency: String
    let timePerDay: String
    let voicePreference: String
    let nsfwFilter: Bool
}

private struct SeedOrg: Decodable {
    let orgId: String
    let name: String
    let billingEmail: String
    let createdAt: String?
}

private struct SeedMembership: Decodable {
    let orgId: String
    let userId: String
    let role: String
}

private struct SeedSource: Decodable {
    let sourceId: String
    let userId: String
    let orgId: String?
    let type: String
    let uri: String
    let language: String?
    let metaJSON: String
    let firstSeenAt: String?
    let lastIngestedAt: String?
}

private struct SeedTranscript: Decodable {
    let transcriptId: String
    let sourceId: String
    let durationSec: Double
    let segments: [SeedSegment]
}

private struct SeedSegment: Decodable {
    let speaker: String
    let text: String
    let start: Double
    let end: Double
    let isStarred: Bool
}

private struct SeedCard: Decodable {
    let cardId: String
    let userId: String
    let sourceType: String?
    let sourceId: String?
    let sourceLoc: String?
    let l1Text: String
    let l2Text: String
    let gloss: String
    let pos: String
    let cefr: String
    let imageURL: String
    let audioURL: String?
    let exampleL2: String
    let exampleL1: String
    let tags: [String]
    let createdAt: String?
    let strength: Double
    let ease: Double
    let nextDueAt: String?
}

private struct SeedReview: Decodable {
    let reviewId: String
    let cardId: String
    let userId: String
    let dueAt: String?
    let shownAt: String?
    let grade: Int
    let ease: Double
    let intervalDays: Double
    let nextDueAt: String?
    let device: String
}

private struct SeedUsageEvent: Decodable {
    let eventId: String
    let userId: String
    let orgId: String?
    let type: String
    let createdAt: String?
    let payloadJSON: String
}

private struct SeedWeeklyUsage: Decodable {
    let orgId: String?
    let userId: String
    let weekStart: String?
    let transcripts: Int
    let cardsReviewed: Int
    let newCards: Int
    let activeMinutes: Int
    let lastActivityAt: String?
}
