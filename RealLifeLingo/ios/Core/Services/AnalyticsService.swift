import Foundation

public enum TSVExportType: String, CaseIterable {
    case cards
    case reviews
    case sources
    case userProfile = "user_profile"
    case b2bUsage = "b2b_usage"
    case b2bOrgMetrics = "b2b_org_metrics"
}

public final class AnalyticsService {
    private let usageRepository: UsageEventRepositoryType
    private let weeklyUsageRepository: WeeklyUsageRepositoryType
    private let cardRepository: CardRepositoryType
    private let reviewRepository: ReviewRepositoryType
    private let sourceRepository: SourceRepositoryType
    private let membershipRepository: MembershipRepositoryType
    private let orgRepository: OrgRepositoryType
    private let userRepository: UserRepositoryType

    public init(usageRepository: UsageEventRepositoryType,
                weeklyUsageRepository: WeeklyUsageRepositoryType,
                cardRepository: CardRepositoryType,
                reviewRepository: ReviewRepositoryType,
                sourceRepository: SourceRepositoryType,
                membershipRepository: MembershipRepositoryType,
                orgRepository: OrgRepositoryType,
                userRepository: UserRepositoryType) {
        self.usageRepository = usageRepository
        self.weeklyUsageRepository = weeklyUsageRepository
        self.cardRepository = cardRepository
        self.reviewRepository = reviewRepository
        self.sourceRepository = sourceRepository
        self.membershipRepository = membershipRepository
        self.orgRepository = orgRepository
        self.userRepository = userRepository
    }

    public func nightlyRollup(date: Date = Date()) {
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let users = userRepository.fetchAll()
        let membershipsByUser = Dictionary(grouping: users.flatMap { user in
            membershipRepository.memberships(for: user.id)
        }, by: { $0.userId })
        for user in users {
            let usageEvents = usageRepository.events(for: user.id, since: weekStart)
            let reviews = reviewRepository.reviews(for: user.id, since: weekStart)
            let transcripts = usageEvents.filter { $0.type == .transcribe }.count
            let newCards = usageEvents.filter { $0.type == .aiGenerate }.count
            let activeMinutes = usageEvents.count * 3
            let lastActivity = usageEvents.first?.createdAt ?? reviews.first?.shownAt
            let base = WeeklyUsage(orgId: nil, userId: user.id, weekStart: weekStart, transcripts: transcripts, cardsReviewed: reviews.count, newCards: newCards, activeMinutes: activeMinutes, lastActivityAt: lastActivity)
            weeklyUsageRepository.save(base)
            for membership in membershipsByUser[user.id] ?? [] {
                let orgUsage = WeeklyUsage(orgId: membership.orgId, userId: user.id, weekStart: weekStart, transcripts: transcripts, cardsReviewed: reviews.count, newCards: newCards, activeMinutes: activeMinutes, lastActivityAt: lastActivity)
                weeklyUsageRepository.save(orgUsage)
            }
        }
    }

    public func export(type: TSVExportType) -> String {
        switch type {
        case .cards:
            return exportCards()
        case .reviews:
            return exportReviews()
        case .sources:
            return exportSources()
        case .userProfile:
            return exportUserProfiles()
        case .b2bUsage:
            return exportB2BUsage()
        case .b2bOrgMetrics:
            return exportOrgMetrics()
        }
    }

    private func exportCards() -> String {
        let cards = userRepository.fetchAll().flatMap { cardRepository.cards(for: $0.id) }
        var rows = ["card_id\tuser_id\tsource_type\tsource_id\tsource_loc\tl1_text\tl2_text\tgloss\tpos\tcefr\timage_uri\taudio_uri\texample_l2\texample_l1\ttags\tcreated_at"]
        for card in cards {
            rows.append([card.id, card.userId, card.sourceType?.rawValue ?? "", card.sourceId ?? "", card.sourceLoc ?? "", card.l1Text, card.l2Text, card.gloss, card.pos, card.cefr, card.imageURL, card.audioURL ?? "", card.exampleL2, card.exampleL1, card.tags.joined(separator: ","), ISO8601DateFormatter().string(from: card.createdAt)].joined(separator: "\t"))
        }
        return rows.joined(separator: "\n")
    }

    private func exportReviews() -> String {
        let users = userRepository.fetchAll()
        var rows = ["review_id\tcard_id\tuser_id\tdue_at\tshown_at\tgrade\tease_ivl\tinterval_s\tnext_due_at\tdevice"]
        for user in users {
            let reviews = reviewRepository.reviews(for: user.id, since: Date.distantPast)
            for review in reviews {
                rows.append([review.id, review.cardId, review.userId, review.dueAt.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "", ISO8601DateFormatter().string(from: review.shownAt), "\(review.grade)", String(format: "%.2f", review.ease), String(format: "%.0f", review.intervalDays * 86400), ISO8601DateFormatter().string(from: review.nextDueAt), review.device].joined(separator: "\t"))
            }
        }
        return rows.joined(separator: "\n")
    }

    private func exportSources() -> String {
        let users = userRepository.fetchAll()
        var rows = ["source_id\tuser_id\ttype\tpath_or_uri\tlanguage\tmeta_json\tfirst_seen_at\tlast_ingested_at"]
        for user in users {
            for source in sourceRepository.sources(for: user.id) {
                rows.append([source.id, source.userId, source.type.rawValue, source.uri, source.language ?? "", source.metaJSON, ISO8601DateFormatter().string(from: source.firstSeenAt), source.lastIngestedAt.flatMap { ISO8601DateFormatter().string(from: $0) } ?? ""].joined(separator: "\t"))
            }
        }
        return rows.joined(separator: "\n")
    }

    private func exportUserProfiles() -> String {
        let users = userRepository.fetchAll()
        var rows = ["user_id\tl1\tl2\tproficiency\thobbies\ttime_per_day\tgoal_daily_new\tvoice_preference\tnsfw_filter"]
        for user in users {
            rows.append([user.id, user.l1, user.l2, user.proficiency, user.hobbies, user.timePerDay, "\(user.goalDailyNew)", user.voicePreference, user.nsfwFilter ? "true" : "false"].joined(separator: "\t"))
        }
        return rows.joined(separator: "\n")
    }

    private func exportB2BUsage() -> String {
        let usages = userRepository.fetchAll().flatMap { user -> [WeeklyUsage] in
            weeklyUsageRepository.weeklyUsage(for: user.id, orgId: nil) + membershipRepository.memberships(for: user.id).flatMap { weeklyUsageRepository.weeklyUsage(for: user.id, orgId: $0.orgId) }
        }
        var rows = ["org_id\tuser_id\tweek_start\ttranscripts_transcribed\tcards_reviewed\tactive_minutes\tnew_cards_created\tlast_activity_at"]
        for usage in usages {
            rows.append([usage.orgId ?? "", usage.userId, ISO8601DateFormatter().string(from: usage.weekStart), "\(usage.transcripts)", "\(usage.cardsReviewed)", "\(usage.activeMinutes)", "\(usage.newCards)", usage.lastActivityAt.flatMap { ISO8601DateFormatter().string(from: $0) } ?? ""].joined(separator: "\t"))
        }
        return rows.joined(separator: "\n")
    }

    private func exportOrgMetrics() -> String {
        let orgs = orgRepository.fetchAll()
        var rows = ["org_id\torg_name\tweek_start\tactive_users\ttotal_transcripts\ttotal_cards\treviews_per_user_avg\ttranscripts_per_user_avg\tretention_rate\tpaying_users"]
        for org in orgs {
            let memberships = membershipRepository.memberships(forOrg: org.id)
            let userIds = memberships.map { $0.userId }
            let weeklyUsage = userIds.flatMap { weeklyUsageRepository.weeklyUsage(for: $0, orgId: org.id) }
            let grouped = Dictionary(grouping: weeklyUsage, by: { $0.weekStart })
            for (weekStart, entries) in grouped {
                let activeUsers = Set(entries.map { $0.userId }).count
                let totalTranscripts = entries.map { $0.transcripts }.reduce(0, +)
                let totalCards = entries.map { $0.newCards }.reduce(0, +)
                let totalReviews = entries.map { $0.cardsReviewed }.reduce(0, +)
                let reviewsPerUser = activeUsers > 0 ? Double(totalReviews) / Double(activeUsers) : 0
                let transcriptsPerUser = activeUsers > 0 ? Double(totalTranscripts) / Double(activeUsers) : 0
                let retentionRate = activeUsers == 0 ? 0 : Double(entries.filter { $0.activeMinutes > 0 }.count) / Double(activeUsers)
                rows.append([org.id, org.name, ISO8601DateFormatter().string(from: weekStart), "\(activeUsers)", "\(totalTranscripts)", "\(totalCards)", String(format: "%.2f", reviewsPerUser), String(format: "%.2f", transcriptsPerUser), String(format: "%.2f", retentionRate), "\(activeUsers)"].joined(separator: "\t"))
            }
        }
        return rows.joined(separator: "\n")
    }
}
