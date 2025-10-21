import Foundation
import CoreData

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

extension UserProfile {
    init(entity: UserEntity) {
        self.init(
            id: entity.userId,
            email: entity.email,
            displayName: entity.displayName ?? "",
            planTier: PlanTier(rawValue: entity.planTier) ?? .storage,
            lastUsageAt: entity.lastUsageAt,
            nextBillDate: entity.nextBillDate,
            lastBilledAt: entity.lastBilledAt,
            orgIds: (entity.orgIds.flatMap { try? decoder.decode([String].self, from: Data($0.utf8)) }) ?? [],
            lastStateChangeAt: entity.lastStateChangeAt,
            cloudAIEnabled: entity.cloudAIEnabled,
            autoReactivate: entity.autoReactivate,
            goalDailyNew: Int(entity.goalDailyNew),
            hobbies: entity.hobbies ?? "",
            l1: entity.l1 ?? "",
            l2: entity.l2 ?? "",
            proficiency: entity.proficiency ?? "",
            timePerDay: entity.timePerDay ?? "",
            voicePreference: entity.voicePreference ?? "",
            nsfwFilter: entity.nsfwFilter
        )
    }
}

extension Org {
    init(entity: OrgEntity) {
        self.init(id: entity.orgId, name: entity.name, billingEmail: entity.billingEmail, createdAt: entity.createdAt)
    }
}

extension Membership {
    init(entity: MembershipEntity) {
        self.init(orgId: entity.orgId, userId: entity.userId, role: MembershipRole(rawValue: entity.role) ?? .member)
    }
}

extension Source {
    init(entity: SourceEntity) {
        self.init(
            id: entity.sourceId,
            userId: entity.userId,
            orgId: entity.orgId,
            type: SourceType(rawValue: entity.type) ?? .transcript,
            uri: entity.uri,
            language: entity.language,
            metaJSON: entity.metaJSON ?? "{}",
            firstSeenAt: entity.firstSeenAt,
            lastIngestedAt: entity.lastIngestedAt
        )
    }
}

extension Transcript {
    init(entity: TranscriptEntity) {
        let segments: [TranscriptSegment] = (try? decoder.decode([TranscriptSegment].self, from: Data(entity.segmentsJSON.utf8))) ?? []
        self.init(id: entity.transcriptId, sourceId: entity.sourceId, durationSec: entity.durationSec, segments: segments)
    }
}

extension Card {
    init(entity: CardEntity) {
        let tags: [String] = (try? decoder.decode([String].self, from: Data((entity.tags ?? "[]").utf8))) ?? []
        self.init(
            id: entity.cardId,
            userId: entity.userId,
            sourceType: entity.sourceType.flatMap(SourceType.init(rawValue:)),
            sourceId: entity.sourceId,
            sourceLoc: entity.sourceLoc,
            l1Text: entity.l1Text ?? "",
            l2Text: entity.l2Text,
            gloss: entity.gloss ?? "",
            pos: entity.pos ?? "",
            cefr: entity.cefr ?? "",
            imageURL: entity.imageURL ?? "",
            audioURL: entity.audioURL,
            exampleL2: entity.exampleL2 ?? "",
            exampleL1: entity.exampleL1 ?? "",
            tags: tags,
            createdAt: entity.createdAt,
            strength: entity.strength,
            ease: entity.ease,
            nextDueAt: entity.nextDueAt
        )
    }
}

extension Review {
    init(entity: ReviewEntity) {
        self.init(
            id: entity.reviewId,
            cardId: entity.cardId,
            userId: entity.userId,
            dueAt: entity.dueAt,
            shownAt: entity.shownAt,
            grade: Int(entity.grade),
            ease: entity.ease,
            intervalDays: entity.intervalDays,
            nextDueAt: entity.nextDueAt,
            device: entity.device ?? "ios"
        )
    }
}

extension UsageEvent {
    init(entity: UsageEventEntity) {
        self.init(
            id: entity.eventId,
            userId: entity.userId,
            orgId: entity.orgId,
            type: UsageEventType(rawValue: entity.type) ?? .review,
            createdAt: entity.createdAt,
            payloadJSON: entity.payloadJSON ?? "{}"
        )
    }
}

extension WeeklyUsage {
    init(entity: WeeklyUsageEntity) {
        self.init(
            orgId: entity.orgId,
            userId: entity.userId,
            weekStart: entity.weekStart,
            transcripts: Int(entity.transcripts),
            cardsReviewed: Int(entity.cardsReviewed),
            newCards: Int(entity.newCards),
            activeMinutes: Int(entity.activeMinutes),
            lastActivityAt: entity.lastActivityAt
        )
    }
}

extension UserEntity {
    func update(from profile: UserProfile) {
        userId = profile.id
        email = profile.email
        displayName = profile.displayName
        planTier = profile.planTier.rawValue
        lastUsageAt = profile.lastUsageAt
        nextBillDate = profile.nextBillDate
        lastBilledAt = profile.lastBilledAt
        orgIds = (try? String(data: encoder.encode(profile.orgIds), encoding: .utf8))
        lastStateChangeAt = profile.lastStateChangeAt
        cloudAIEnabled = profile.cloudAIEnabled
        autoReactivate = profile.autoReactivate
        goalDailyNew = Int64(profile.goalDailyNew)
        hobbies = profile.hobbies
        l1 = profile.l1
        l2 = profile.l2
        proficiency = profile.proficiency
        timePerDay = profile.timePerDay
        voicePreference = profile.voicePreference
        nsfwFilter = profile.nsfwFilter
    }
}

extension OrgEntity {
    func update(from org: Org) {
        orgId = org.id
        name = org.name
        billingEmail = org.billingEmail
        createdAt = org.createdAt
    }
}

extension MembershipEntity {
    func update(from membership: Membership) {
        orgId = membership.orgId
        userId = membership.userId
        role = membership.role.rawValue
    }
}

extension SourceEntity {
    func update(from source: Source) {
        sourceId = source.id
        userId = source.userId
        orgId = source.orgId
        type = source.type.rawValue
        uri = source.uri
        language = source.language
        metaJSON = source.metaJSON
        firstSeenAt = source.firstSeenAt
        lastIngestedAt = source.lastIngestedAt
    }
}

extension TranscriptEntity {
    func update(from transcript: Transcript) {
        transcriptId = transcript.id
        sourceId = transcript.sourceId
        durationSec = transcript.durationSec
        if let data = try? encoder.encode(transcript.segments),
           let json = String(data: data, encoding: .utf8) {
            segmentsJSON = json
        }
    }
}

extension CardEntity {
    func update(from card: Card) {
        cardId = card.id
        userId = card.userId
        sourceType = card.sourceType?.rawValue
        sourceId = card.sourceId
        sourceLoc = card.sourceLoc
        l1Text = card.l1Text
        l2Text = card.l2Text
        gloss = card.gloss
        pos = card.pos
        cefr = card.cefr
        imageURL = card.imageURL
        audioURL = card.audioURL
        exampleL2 = card.exampleL2
        exampleL1 = card.exampleL1
        if let data = try? encoder.encode(card.tags), let json = String(data: data, encoding: .utf8) {
            tags = json
        }
        createdAt = card.createdAt
        strength = card.strength
        ease = card.ease
        nextDueAt = card.nextDueAt
    }
}

extension ReviewEntity {
    func update(from review: Review) {
        reviewId = review.id
        cardId = review.cardId
        userId = review.userId
        dueAt = review.dueAt
        shownAt = review.shownAt
        grade = Int64(review.grade)
        ease = review.ease
        intervalDays = review.intervalDays
        nextDueAt = review.nextDueAt
        device = review.device
    }
}

extension UsageEventEntity {
    func update(from event: UsageEvent) {
        eventId = event.id
        userId = event.userId
        orgId = event.orgId
        type = event.type.rawValue
        createdAt = event.createdAt
        payloadJSON = event.payloadJSON
    }
}

extension WeeklyUsageEntity {
    func update(from usage: WeeklyUsage) {
        orgId = usage.orgId
        userId = usage.userId
        weekStart = usage.weekStart
        transcripts = Int64(usage.transcripts)
        cardsReviewed = Int64(usage.cardsReviewed)
        newCards = Int64(usage.newCards)
        activeMinutes = Int64(usage.activeMinutes)
        lastActivityAt = usage.lastActivityAt
    }
}
