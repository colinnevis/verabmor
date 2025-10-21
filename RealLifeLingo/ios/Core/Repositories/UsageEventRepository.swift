import Foundation
import CoreData

public protocol UsageEventRepositoryType {
    func events(for userId: String, since date: Date?) -> [UsageEvent]
    func save(_ event: UsageEvent)
    func lastAIUsage(for userId: String) -> UsageEvent?
}

public final class UsageEventRepository: CoreDataRepository, UsageEventRepositoryType {
    public func events(for userId: String, since date: Date?) -> [UsageEvent] {
        let request: NSFetchRequest<UsageEventEntity> = UsageEventEntity.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "userId == %@", userId)]
        if let date = date {
            predicates.append(NSPredicate(format: "createdAt >= %@", date as NSDate))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return fetch(request).map(UsageEvent.init(entity:))
    }

    public func save(_ event: UsageEvent) {
        let request: NSFetchRequest<UsageEventEntity> = UsageEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "eventId == %@", event.id)
        let entity = fetchFirst(request) ?? UsageEventEntity(context: viewContext)
        entity.update(from: event)
        save()
    }

    public func lastAIUsage(for userId: String) -> UsageEvent? {
        let request: NSFetchRequest<UsageEventEntity> = UsageEventEntity.fetchRequest()
        let predicate = NSPredicate(format: "userId == %@ AND (type == %@ OR type == %@)", userId, UsageEventType.transcribe.rawValue, UsageEventType.aiGenerate.rawValue)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return fetchFirst(request).map(UsageEvent.init(entity:))
    }
}

private extension UsageEventEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UsageEventEntity> {
        NSFetchRequest<UsageEventEntity>(entityName: "UsageEventEntity")
    }
}
