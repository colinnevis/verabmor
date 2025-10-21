import Foundation
import CoreData

public protocol WeeklyUsageRepositoryType {
    func weeklyUsage(for userId: String, orgId: String?) -> [WeeklyUsage]
    func weeklyUsage(forOrg orgId: String) -> [WeeklyUsage]
    func save(_ usage: WeeklyUsage)
}

public final class WeeklyUsageRepository: CoreDataRepository, WeeklyUsageRepositoryType {
    public func weeklyUsage(for userId: String, orgId: String?) -> [WeeklyUsage] {
        let request: NSFetchRequest<WeeklyUsageEntity> = WeeklyUsageEntity.fetchRequest()
        if let orgId = orgId {
            request.predicate = NSPredicate(format: "userId == %@ AND orgId == %@", userId, orgId)
        } else {
            request.predicate = NSPredicate(format: "userId == %@ AND orgId == nil", userId)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "weekStart", ascending: false)]
        return fetch(request).map(WeeklyUsage.init(entity:))
    }

    public func weeklyUsage(forOrg orgId: String) -> [WeeklyUsage] {
        let request: NSFetchRequest<WeeklyUsageEntity> = WeeklyUsageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orgId == %@", orgId)
        request.sortDescriptors = [NSSortDescriptor(key: "weekStart", ascending: false)]
        return fetch(request).map(WeeklyUsage.init(entity:))
    }

    public func save(_ usage: WeeklyUsage) {
        let request: NSFetchRequest<WeeklyUsageEntity> = WeeklyUsageEntity.fetchRequest()
        if let orgId = usage.orgId {
            request.predicate = NSPredicate(format: "userId == %@ AND orgId == %@ AND weekStart == %@", usage.userId, orgId, usage.weekStart as NSDate)
        } else {
            request.predicate = NSPredicate(format: "userId == %@ AND orgId == nil AND weekStart == %@", usage.userId, usage.weekStart as NSDate)
        }
        let entity = fetchFirst(request) ?? WeeklyUsageEntity(context: viewContext)
        entity.update(from: usage)
        save()
    }
}

private extension WeeklyUsageEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<WeeklyUsageEntity> {
        NSFetchRequest<WeeklyUsageEntity>(entityName: "WeeklyUsageEntity")
    }
}
