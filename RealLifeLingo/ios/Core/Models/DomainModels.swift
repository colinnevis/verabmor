import Foundation

public enum PlanTier: String, Codable, CaseIterable {
    case storage
    case active
    case team
}

public enum MembershipRole: String, Codable {
    case admin
    case member
}

public enum SourceType: String, Codable {
    case transcript
    case kindle
    case subtitle
}

public enum UsageEventType: String, Codable {
    case transcribe
    case aiGenerate = "ai_generate"
    case review
}

public struct UserProfile: Identifiable, Codable {
    public let id: String
    public var email: String
    public var displayName: String
    public var planTier: PlanTier
    public var lastUsageAt: Date?
    public var nextBillDate: Date?
    public var lastBilledAt: Date?
    public var orgIds: [String]
    public var lastStateChangeAt: Date?
    public var cloudAIEnabled: Bool
    public var autoReactivate: Bool
    public var goalDailyNew: Int
    public var hobbies: String
    public var l1: String
    public var l2: String
    public var proficiency: String
    public var timePerDay: String
    public var voicePreference: String
    public var nsfwFilter: Bool
}

public struct Org: Identifiable, Codable {
    public let id: String
    public var name: String
    public var billingEmail: String
    public var createdAt: Date
}

public struct Membership: Identifiable, Codable {
    public var id: String { "\(orgId)-\(userId)" }
    public var orgId: String
    public var userId: String
    public var role: MembershipRole
}

public struct Source: Identifiable, Codable {
    public let id: String
    public var userId: String
    public var orgId: String?
    public var type: SourceType
    public var uri: String
    public var language: String?
    public var metaJSON: String
    public var firstSeenAt: Date
    public var lastIngestedAt: Date?
}

public struct TranscriptSegment: Codable, Identifiable {
    public let id: UUID
    public var speaker: String
    public var text: String
    public var start: TimeInterval
    public var end: TimeInterval
    public var isStarred: Bool
}

public struct Transcript: Identifiable, Codable {
    public let id: String
    public var sourceId: String
    public var durationSec: Double
    public var segments: [TranscriptSegment]
}

public struct Card: Identifiable, Codable {
    public let id: String
    public var userId: String
    public var sourceType: SourceType?
    public var sourceId: String?
    public var sourceLoc: String?
    public var l1Text: String
    public var l2Text: String
    public var gloss: String
    public var pos: String
    public var cefr: String
    public var imageURL: String
    public var audioURL: String?
    public var exampleL2: String
    public var exampleL1: String
    public var tags: [String]
    public var createdAt: Date
    public var strength: Double
    public var ease: Double
    public var nextDueAt: Date?
}

public struct Review: Identifiable, Codable {
    public let id: String
    public var cardId: String
    public var userId: String
    public var dueAt: Date?
    public var shownAt: Date
    public var grade: Int
    public var ease: Double
    public var intervalDays: Double
    public var nextDueAt: Date
    public var device: String
}

public struct UsageEvent: Identifiable, Codable {
    public let id: String
    public var userId: String
    public var orgId: String?
    public var type: UsageEventType
    public var createdAt: Date
    public var payloadJSON: String
}

public struct WeeklyUsage: Identifiable, Codable {
    public var id: String { "\(orgId ?? "personal")-\(userId)-\(weekStart.timeIntervalSince1970)" }
    public var orgId: String?
    public var userId: String
    public var weekStart: Date
    public var transcripts: Int
    public var cardsReviewed: Int
    public var newCards: Int
    public var activeMinutes: Int
    public var lastActivityAt: Date?
}

public struct CardExtractionCandidate: Identifiable {
    public var id: String { term }
    public let term: String
    public let frequency: Int
    public let novelty: Double
    public let isStarred: Bool
    public let examples: [String]
}

public struct ImageGenerationResult: Codable {
    public let url: String
}

public struct ExampleResult: Codable {
    public let l2: String
    public let l1: String
}
