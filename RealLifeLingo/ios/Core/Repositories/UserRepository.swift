import Foundation
import CoreData

public protocol UserRepositoryType {
    func getUser(id: String) -> UserProfile?
    func fetchAll() -> [UserProfile]
    func save(_ user: UserProfile)
    func updatePlanTier(userId: String, tier: PlanTier, nextBillDate: Date?, lastStateChange: Date)
}

public final class UserRepository: CoreDataRepository, UserRepositoryType {
    public func getUser(id: String) -> UserProfile? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", id)
        guard let entity = fetchFirst(request) else { return nil }
        return UserProfile(entity: entity)
    }

    public func fetchAll() -> [UserProfile] {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        return fetch(request).map(UserProfile.init(entity:))
    }

    public func save(_ user: UserProfile) {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", user.id)
        let entity = fetchFirst(request) ?? UserEntity(context: viewContext)
        entity.update(from: user)
        save()
    }

    public func updatePlanTier(userId: String, tier: PlanTier, nextBillDate: Date?, lastStateChange: Date) {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        let entity = fetchFirst(request) ?? UserEntity(context: viewContext)
        entity.userId = userId
        entity.planTier = tier.rawValue
        entity.nextBillDate = nextBillDate
        entity.lastStateChangeAt = lastStateChange
        save()
    }
}

private extension UserEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
}
