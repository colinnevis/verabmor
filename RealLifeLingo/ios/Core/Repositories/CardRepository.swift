import Foundation
import CoreData

public protocol CardRepositoryType {
    func cards(for userId: String) -> [Card]
    func dueCards(for userId: String, on date: Date) -> [Card]
    func search(userId: String, query: String?, tags: [String]) -> [Card]
    func save(_ card: Card)
    func save(_ cards: [Card])
}

public final class CardRepository: CoreDataRepository, CardRepositoryType {
    public func cards(for userId: String) -> [Card] {
        let request: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return fetch(request).map(Card.init(entity:))
    }

    public func dueCards(for userId: String, on date: Date) -> [Card] {
        let request: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        let predicate = NSPredicate(format: "userId == %@ AND nextDueAt <= %@", userId, date as NSDate)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "nextDueAt", ascending: true)]
        return fetch(request).map(Card.init(entity:))
    }

    public func search(userId: String, query: String?, tags: [String]) -> [Card] {
        var predicates: [NSPredicate] = [NSPredicate(format: "userId == %@", userId)]
        if let query = query, !query.isEmpty {
            predicates.append(NSPredicate(format: "l2Text CONTAINS[cd] %@ OR gloss CONTAINS[cd] %@", query, query))
        }
        if !tags.isEmpty {
            tags.forEach { tag in
                predicates.append(NSPredicate(format: "tags CONTAINS[cd] %@", tag))
            }
        }
        let request: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return fetch(request).map(Card.init(entity:))
    }

    public func save(_ card: Card) {
        let request: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "cardId == %@", card.id)
        let entity = fetchFirst(request) ?? CardEntity(context: viewContext)
        entity.update(from: card)
        save()
    }

    public func save(_ cards: [Card]) {
        cards.forEach { save($0) }
    }
}

private extension CardEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CardEntity> {
        NSFetchRequest<CardEntity>(entityName: "CardEntity")
    }
}
