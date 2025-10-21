import Foundation
import CoreData

public protocol OrgRepositoryType {
    func fetchOrg(id: String) -> Org?
    func fetchAll() -> [Org]
    func save(_ org: Org)
}

public final class OrgRepository: CoreDataRepository, OrgRepositoryType {
    public func fetchOrg(id: String) -> Org? {
        let request: NSFetchRequest<OrgEntity> = OrgEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orgId == %@", id)
        return fetchFirst(request).map(Org.init(entity:))
    }

    public func fetchAll() -> [Org] {
        let request: NSFetchRequest<OrgEntity> = OrgEntity.fetchRequest()
        return fetch(request).map(Org.init(entity:))
    }

    public func save(_ org: Org) {
        let request: NSFetchRequest<OrgEntity> = OrgEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orgId == %@", org.id)
        let entity = fetchFirst(request) ?? OrgEntity(context: viewContext)
        entity.update(from: org)
        save()
    }
}

private extension OrgEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<OrgEntity> {
        NSFetchRequest<OrgEntity>(entityName: "OrgEntity")
    }
}
