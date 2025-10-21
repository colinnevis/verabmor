import Foundation

public final class SRSService {
    private let cardRepository: CardRepositoryType
    private let reviewRepository: ReviewRepositoryType
    private let usageRepository: UsageEventRepositoryType
    private let eventProcessor: UsageEventProcessing

    public init(cardRepository: CardRepositoryType,
                reviewRepository: ReviewRepositoryType,
                usageRepository: UsageEventRepositoryType,
                eventProcessor: UsageEventProcessing) {
        self.cardRepository = cardRepository
        self.reviewRepository = reviewRepository
        self.usageRepository = usageRepository
        self.eventProcessor = eventProcessor
    }

    public func dailyQueue(for user: UserProfile, date: Date = Date()) -> [Card] {
        let due = cardRepository.dueCards(for: user.id, on: date)
        if due.count >= user.goalDailyNew {
            return due
        }
        let newCards = cardRepository.cards(for: user.id).filter { $0.nextDueAt == nil }
        let newLimit = max(0, user.goalDailyNew - due.count)
        return due + newCards.prefix(newLimit)
    }

    @discardableResult
    public func grade(card: Card, grade: Int, user: UserProfile, device: String) -> Card {
        let now = Date()
        var updatedCard = card
        let repetitions = Int(card.strength)
        var newRepetitions = repetitions
        var ease = card.ease
        var intervalDays: Double = 1
        if grade < 3 {
            newRepetitions = 0
            ease = max(1.3, ease - 0.2)
            intervalDays = 1
        } else {
            newRepetitions += 1
            if newRepetitions == 1 {
                intervalDays = 1
            } else if newRepetitions == 2 {
                intervalDays = 6
            } else {
                let previousInterval = max(card.nextDueAt.map { $0.timeIntervalSince(now) / 86400 } ?? 1, 1)
                intervalDays = previousInterval * ease
            }
            let delta = 0.1 - Double(5 - grade) * (0.08 + Double(5 - grade) * 0.02)
            ease = max(1.3, ease + delta)
        }
        let nextDue = Calendar.current.date(byAdding: .day, value: Int(intervalDays.rounded()), to: now) ?? now.addingTimeInterval(intervalDays * 86400)
        updatedCard.nextDueAt = nextDue
        updatedCard.ease = ease
        updatedCard.strength = Double(newRepetitions)
        cardRepository.save(updatedCard)

        let review = Review(
            id: UUID().uuidString,
            cardId: card.id,
            userId: user.id,
            dueAt: card.nextDueAt,
            shownAt: now,
            grade: grade,
            ease: ease,
            intervalDays: intervalDays,
            nextDueAt: nextDue,
            device: device
        )
        reviewRepository.save(review)
        let event = UsageEvent(id: UUID().uuidString, userId: user.id, orgId: nil, type: .review, createdAt: now, payloadJSON: "{\"cardId\":\"\(card.id)\",\"grade\":\(grade)}")
        usageRepository.save(event)
        eventProcessor.process(event: event)
        return updatedCard
    }
}
