import Foundation
import CoreData

open class CoreDataRepository {
    public let persistence: PersistenceController

    public init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    public var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }

    public func fetch<Entity: NSManagedObject>(_ request: NSFetchRequest<Entity>) -> [Entity] {
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed fetch: \(error)")
            return []
        }
    }

    public func fetchFirst<Entity: NSManagedObject>(_ request: NSFetchRequest<Entity>) -> Entity? {
        request.fetchLimit = 1
        return fetch(request).first
    }

    public func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
    }

    public func save() {
        persistence.save()
    }
}
