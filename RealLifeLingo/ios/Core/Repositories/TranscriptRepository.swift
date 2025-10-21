import Foundation
import CoreData

public protocol TranscriptRepositoryType {
    func transcript(for sourceId: String) -> Transcript?
    func save(_ transcript: Transcript)
}

public final class TranscriptRepository: CoreDataRepository, TranscriptRepositoryType {
    public func transcript(for sourceId: String) -> Transcript? {
        let request: NSFetchRequest<TranscriptEntity> = TranscriptEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sourceId == %@", sourceId)
        return fetchFirst(request).map(Transcript.init(entity:))
    }

    public func save(_ transcript: Transcript) {
        let request: NSFetchRequest<TranscriptEntity> = TranscriptEntity.fetchRequest()
        request.predicate = NSPredicate(format: "transcriptId == %@", transcript.id)
        let entity = fetchFirst(request) ?? TranscriptEntity(context: viewContext)
        entity.update(from: transcript)
        save()
    }
}

private extension TranscriptEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TranscriptEntity> {
        NSFetchRequest<TranscriptEntity>(entityName: "TranscriptEntity")
    }
}
