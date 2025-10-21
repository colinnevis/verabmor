import Foundation
import CoreData

public protocol SourceRepositoryType {
    func sources(for userId: String) -> [Source]
    func fetch(sourceId: String) -> Source?
    func save(_ source: Source)
}

public final class SourceRepository: CoreDataRepository, SourceRepositoryType {
    public func sources(for userId: String) -> [Source] {
        let request: NSFetchRequest<SourceEntity> = SourceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "firstSeenAt", ascending: false)]
        return fetch(request).map(Source.init(entity:))
    }

    public func fetch(sourceId: String) -> Source? {
        let request: NSFetchRequest<SourceEntity> = SourceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sourceId == %@", sourceId)
        return fetchFirst(request).map(Source.init(entity:))
    }

    public func save(_ source: Source) {
        let request: NSFetchRequest<SourceEntity> = SourceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sourceId == %@", source.id)
        let entity = fetchFirst(request) ?? SourceEntity(context: viewContext)
        entity.update(from: source)
        save()
    }
}

private extension SourceEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceEntity> {
        NSFetchRequest<SourceEntity>(entityName: "SourceEntity")
    }
}
