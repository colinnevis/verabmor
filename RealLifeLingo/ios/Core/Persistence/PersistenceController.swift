import Foundation
import CoreData

public final class PersistenceController {
    public static let shared = PersistenceController()

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        let model = PersistenceController.makeModel()
        container = NSPersistentContainer(name: "RealLifeLingo", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    public func save(context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            print("Failed saving context: \(error)")
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        func attribute(_ name: String, _ type: NSAttributeType, _ optional: Bool = false) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            return attr
        }

        func stringAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            attribute(name, .stringAttributeType, optional)
        }

        func dateAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            attribute(name, .dateAttributeType, optional)
        }

        func doubleAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            attribute(name, .doubleAttributeType, optional)
        }

        func intAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            attribute(name, .integer64AttributeType, optional)
        }

        func boolAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            attribute(name, .booleanAttributeType, optional)
        }

        let user = NSEntityDescription()
        user.name = "UserEntity"
        user.managedObjectClassName = NSStringFromClass(UserEntity.self)
        user.properties = [
            stringAttr("userId"),
            stringAttr("email"),
            stringAttr("displayName", optional: true),
            stringAttr("planTier"),
            dateAttr("lastUsageAt", optional: true),
            dateAttr("nextBillDate", optional: true),
            dateAttr("lastBilledAt", optional: true),
            stringAttr("orgIds", optional: true),
            dateAttr("lastStateChangeAt", optional: true),
            boolAttr("cloudAIEnabled"),
            boolAttr("autoReactivate"),
            intAttr("goalDailyNew"),
            stringAttr("hobbies", optional: true),
            stringAttr("l1", optional: true),
            stringAttr("l2", optional: true),
            stringAttr("proficiency", optional: true),
            stringAttr("timePerDay", optional: true),
            stringAttr("voicePreference", optional: true),
            boolAttr("nsfwFilter")
        ]

        let org = NSEntityDescription()
        org.name = "OrgEntity"
        org.managedObjectClassName = NSStringFromClass(OrgEntity.self)
        org.properties = [
            stringAttr("orgId"),
            stringAttr("name"),
            stringAttr("billingEmail"),
            dateAttr("createdAt")
        ]

        let membership = NSEntityDescription()
        membership.name = "MembershipEntity"
        membership.managedObjectClassName = NSStringFromClass(MembershipEntity.self)
        membership.properties = [
            stringAttr("orgId"),
            stringAttr("userId"),
            stringAttr("role")
        ]

        let source = NSEntityDescription()
        source.name = "SourceEntity"
        source.managedObjectClassName = NSStringFromClass(SourceEntity.self)
        source.properties = [
            stringAttr("sourceId"),
            stringAttr("userId"),
            stringAttr("orgId", optional: true),
            stringAttr("type"),
            stringAttr("uri"),
            stringAttr("language", optional: true),
            stringAttr("metaJSON", optional: true),
            dateAttr("firstSeenAt"),
            dateAttr("lastIngestedAt", optional: true)
        ]

        let transcript = NSEntityDescription()
        transcript.name = "TranscriptEntity"
        transcript.managedObjectClassName = NSStringFromClass(TranscriptEntity.self)
        transcript.properties = [
            stringAttr("transcriptId"),
            stringAttr("sourceId"),
            doubleAttr("durationSec"),
            stringAttr("segmentsJSON")
        ]

        let card = NSEntityDescription()
        card.name = "CardEntity"
        card.managedObjectClassName = NSStringFromClass(CardEntity.self)
        card.properties = [
            stringAttr("cardId"),
            stringAttr("userId"),
            stringAttr("sourceType", optional: true),
            stringAttr("sourceId", optional: true),
            stringAttr("sourceLoc", optional: true),
            stringAttr("l1Text", optional: true),
            stringAttr("l2Text"),
            stringAttr("gloss", optional: true),
            stringAttr("pos", optional: true),
            stringAttr("cefr", optional: true),
            stringAttr("imageURL", optional: true),
            stringAttr("audioURL", optional: true),
            stringAttr("exampleL2", optional: true),
            stringAttr("exampleL1", optional: true),
            stringAttr("tags", optional: true),
            dateAttr("createdAt"),
            doubleAttr("strength", optional: true),
            doubleAttr("ease"),
            dateAttr("nextDueAt", optional: true)
        ]

        let review = NSEntityDescription()
        review.name = "ReviewEntity"
        review.managedObjectClassName = NSStringFromClass(ReviewEntity.self)
        review.properties = [
            stringAttr("reviewId"),
            stringAttr("cardId"),
            stringAttr("userId"),
            dateAttr("dueAt", optional: true),
            dateAttr("shownAt"),
            intAttr("grade"),
            doubleAttr("ease"),
            doubleAttr("intervalDays"),
            dateAttr("nextDueAt"),
            stringAttr("device", optional: true)
        ]

        let usage = NSEntityDescription()
        usage.name = "UsageEventEntity"
        usage.managedObjectClassName = NSStringFromClass(UsageEventEntity.self)
        usage.properties = [
            stringAttr("eventId"),
            stringAttr("userId"),
            stringAttr("orgId", optional: true),
            stringAttr("type"),
            dateAttr("createdAt"),
            stringAttr("payloadJSON", optional: true)
        ]

        let weekly = NSEntityDescription()
        weekly.name = "WeeklyUsageEntity"
        weekly.managedObjectClassName = NSStringFromClass(WeeklyUsageEntity.self)
        weekly.properties = [
            stringAttr("orgId", optional: true),
            stringAttr("userId"),
            dateAttr("weekStart"),
            intAttr("transcripts"),
            intAttr("cardsReviewed"),
            intAttr("newCards"),
            intAttr("activeMinutes"),
            dateAttr("lastActivityAt", optional: true)
        ]

        model.entities = [user, org, membership, source, transcript, card, review, usage, weekly]
        return model
    }
}
