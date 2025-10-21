import Foundation
import CoreData

@objc(UserEntity)
public final class UserEntity: NSManagedObject {
    @NSManaged public var userId: String
    @NSManaged public var email: String
    @NSManaged public var displayName: String?
    @NSManaged public var planTier: String
    @NSManaged public var lastUsageAt: Date?
    @NSManaged public var nextBillDate: Date?
    @NSManaged public var lastBilledAt: Date?
    @NSManaged public var orgIds: String?
    @NSManaged public var lastStateChangeAt: Date?
    @NSManaged public var cloudAIEnabled: Bool
    @NSManaged public var autoReactivate: Bool
    @NSManaged public var goalDailyNew: Int64
    @NSManaged public var hobbies: String?
    @NSManaged public var l1: String?
    @NSManaged public var l2: String?
    @NSManaged public var proficiency: String?
    @NSManaged public var timePerDay: String?
    @NSManaged public var voicePreference: String?
    @NSManaged public var nsfwFilter: Bool
}

@objc(OrgEntity)
public final class OrgEntity: NSManagedObject {
    @NSManaged public var orgId: String
    @NSManaged public var name: String
    @NSManaged public var billingEmail: String
    @NSManaged public var createdAt: Date
}

@objc(MembershipEntity)
public final class MembershipEntity: NSManagedObject {
    @NSManaged public var orgId: String
    @NSManaged public var userId: String
    @NSManaged public var role: String
}

@objc(SourceEntity)
public final class SourceEntity: NSManagedObject {
    @NSManaged public var sourceId: String
    @NSManaged public var userId: String
    @NSManaged public var orgId: String?
    @NSManaged public var type: String
    @NSManaged public var uri: String
    @NSManaged public var language: String?
    @NSManaged public var metaJSON: String?
    @NSManaged public var firstSeenAt: Date
    @NSManaged public var lastIngestedAt: Date?
}

@objc(TranscriptEntity)
public final class TranscriptEntity: NSManagedObject {
    @NSManaged public var transcriptId: String
    @NSManaged public var sourceId: String
    @NSManaged public var durationSec: Double
    @NSManaged public var segmentsJSON: String
}

@objc(CardEntity)
public final class CardEntity: NSManagedObject {
    @NSManaged public var cardId: String
    @NSManaged public var userId: String
    @NSManaged public var sourceType: String?
    @NSManaged public var sourceId: String?
    @NSManaged public var sourceLoc: String?
    @NSManaged public var l1Text: String?
    @NSManaged public var l2Text: String
    @NSManaged public var gloss: String?
    @NSManaged public var pos: String?
    @NSManaged public var cefr: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var audioURL: String?
    @NSManaged public var exampleL2: String?
    @NSManaged public var exampleL1: String?
    @NSManaged public var tags: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var strength: Double
    @NSManaged public var ease: Double
    @NSManaged public var nextDueAt: Date?
}

@objc(ReviewEntity)
public final class ReviewEntity: NSManagedObject {
    @NSManaged public var reviewId: String
    @NSManaged public var cardId: String
    @NSManaged public var userId: String
    @NSManaged public var dueAt: Date?
    @NSManaged public var shownAt: Date
    @NSManaged public var grade: Int64
    @NSManaged public var ease: Double
    @NSManaged public var intervalDays: Double
    @NSManaged public var nextDueAt: Date
    @NSManaged public var device: String?
}

@objc(UsageEventEntity)
public final class UsageEventEntity: NSManagedObject {
    @NSManaged public var eventId: String
    @NSManaged public var userId: String
    @NSManaged public var orgId: String?
    @NSManaged public var type: String
    @NSManaged public var createdAt: Date
    @NSManaged public var payloadJSON: String?
}

@objc(WeeklyUsageEntity)
public final class WeeklyUsageEntity: NSManagedObject {
    @NSManaged public var orgId: String?
    @NSManaged public var userId: String
    @NSManaged public var weekStart: Date
    @NSManaged public var transcripts: Int64
    @NSManaged public var cardsReviewed: Int64
    @NSManaged public var newCards: Int64
    @NSManaged public var activeMinutes: Int64
    @NSManaged public var lastActivityAt: Date?
}
