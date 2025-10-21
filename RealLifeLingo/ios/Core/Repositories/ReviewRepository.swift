import Foundation
import CoreData

public protocol ReviewRepositoryType {
    func latestReview(for cardId: String) -> Review?
    func reviews(for userId: String, since date: Date) -> [Review]
    func save(_ review: Review)
}

public final class ReviewRepository: CoreDataRepository, ReviewRepositoryType {
    public func latestReview(for cardId: String) -> Review? {
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "cardId == %@", cardId)
        request.sortDescriptors = [NSSortDescriptor(key: "shownAt", ascending: false)]
        return fetchFirst(request).map(Review.init(entity:))
    }

    public func reviews(for userId: String, since date: Date) -> [Review] {
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND shownAt >= %@", userId, date as NSDate)
        return fetch(request).map(Review.init(entity:))
    }

    public func save(_ review: Review) {
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "reviewId == %@", review.id)
        let entity = fetchFirst(request) ?? ReviewEntity(context: viewContext)
        entity.update(from: review)
        save()
    }
}

private extension ReviewEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ReviewEntity> {
        NSFetchRequest<ReviewEntity>(entityName: "ReviewEntity")
    }
}
