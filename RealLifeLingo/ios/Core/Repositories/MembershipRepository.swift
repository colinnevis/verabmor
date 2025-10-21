import Foundation
import CoreData

public protocol MembershipRepositoryType {
    func memberships(for userId: String) -> [Membership]
    func memberships(forOrg orgId: String) -> [Membership]
    func save(_ membership: Membership)
}

public final class MembershipRepository: CoreDataRepository, MembershipRepositoryType {
    public func memberships(for userId: String) -> [Membership] {
        let request: NSFetchRequest<MembershipEntity> = MembershipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        return fetch(request).map(Membership.init(entity:))
    }

    public func memberships(forOrg orgId: String) -> [Membership] {
        let request: NSFetchRequest<MembershipEntity> = MembershipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orgId == %@", orgId)
        return fetch(request).map(Membership.init(entity:))
    }

    public func save(_ membership: Membership) {
        let request: NSFetchRequest<MembershipEntity> = MembershipEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orgId == %@ AND userId == %@", membership.orgId, membership.userId)
        let entity = fetchFirst(request) ?? MembershipEntity(context: viewContext)
        entity.update(from: membership)
        save()
    }
}

private extension MembershipEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MembershipEntity> {
        NSFetchRequest<MembershipEntity>(entityName: "MembershipEntity")
    }
}
