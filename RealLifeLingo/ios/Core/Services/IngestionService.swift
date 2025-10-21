import Foundation

public struct IngestionResult {
    public let source: Source
    public let transcript: Transcript?
    public let cards: [Card]
}

public final class IngestionService {
    private let sourceRepository: SourceRepositoryType
    private let transcriptRepository: TranscriptRepositoryType
    private let cardCreationService: CardCreationService
    private let nlpService: NLPService
    private let usageRepository: UsageEventRepositoryType
    private let eventProcessor: UsageEventProcessing
    private let kindleParser = KindleParser()
    private let readwiseParser = ReadwiseParser()
    private let subtitleParser = SubtitleParser()

    public init(sourceRepository: SourceRepositoryType,
                transcriptRepository: TranscriptRepositoryType,
                cardCreationService: CardCreationService,
                nlpService: NLPService,
                usageRepository: UsageEventRepositoryType,
                eventProcessor: UsageEventProcessing) {
        self.sourceRepository = sourceRepository
        self.transcriptRepository = transcriptRepository
        self.cardCreationService = cardCreationService
        self.nlpService = nlpService
        self.usageRepository = usageRepository
        self.eventProcessor = eventProcessor
    }

    public func importKindle(data: Data, user: UserProfile, orgId: String? = nil) async -> IngestionResult? {
        let highlights = kindleParser.parse(data: data)
        guard !highlights.isEmpty else { return nil }
        let language = nlpService.detectLanguage(for: highlights.map { $0.text }.joined(separator: " ")) ?? user.l2
        let source = Source(id: UUID().uuidString, userId: user.id, orgId: orgId, type: .kindle, uri: "kindle://import/\(UUID().uuidString)", language: language, metaJSON: encodeMeta(highlights: highlights), firstSeenAt: Date(), lastIngestedAt: Date())
        sourceRepository.save(source)
        let cards = await cardCreationService.generateCards(user: user, source: source, transcript: nil, textBlocks: highlights.map { $0.text })
        return IngestionResult(source: source, transcript: nil, cards: cards)
    }

    public func importReadwiseCSV(data: Data, user: UserProfile, orgId: String? = nil) async -> IngestionResult? {
        let highlights = readwiseParser.parseCSV(data: data)
        return await importReadwiseHighlights(highlights: highlights, user: user, orgId: orgId)
    }

    public func importReadwiseJSON(data: Data, user: UserProfile, orgId: String? = nil) async -> IngestionResult? {
        let highlights = readwiseParser.parseJSON(data: data)
        return await importReadwiseHighlights(highlights: highlights, user: user, orgId: orgId)
    }

    public func importSubtitles(data: Data, fileExtension: String, user: UserProfile, orgId: String? = nil) async -> IngestionResult? {
        let lines: [SubtitleLine]
        if fileExtension.lowercased() == "srt" {
            lines = subtitleParser.parseSRT(data: data)
        } else {
            lines = subtitleParser.parseVTT(data: data)
        }
        guard !lines.isEmpty else { return nil }
        let language = nlpService.detectLanguage(for: lines.map { $0.text }.joined(separator: " ")) ?? user.l2
        let source = Source(id: UUID().uuidString, userId: user.id, orgId: orgId, type: .subtitle, uri: "subtitle://import/\(UUID().uuidString)", language: language, metaJSON: encodeMeta(subtitles: lines), firstSeenAt: Date(), lastIngestedAt: Date())
        sourceRepository.save(source)
        let transcriptSegments = lines.map { line -> TranscriptSegment in
            TranscriptSegment(id: UUID(), speaker: "Teacher", text: line.text, start: line.start, end: line.end, isStarred: false)
        }
        let transcript = Transcript(id: UUID().uuidString, sourceId: source.id, durationSec: lines.last?.end ?? 0, segments: transcriptSegments)
        transcriptRepository.save(transcript)
        let cards = await cardCreationService.generateCards(user: user, source: source, transcript: transcript)
        return IngestionResult(source: source, transcript: transcript, cards: cards)
    }

    public func recordUsage(event: UsageEvent) {
        usageRepository.save(event)
        eventProcessor.process(event: event)
    }

    private func importReadwiseHighlights(highlights: [ReadwiseHighlight], user: UserProfile, orgId: String?) async -> IngestionResult? {
        guard !highlights.isEmpty else { return nil }
        let language = nlpService.detectLanguage(for: highlights.map { $0.text }.joined(separator: " ")) ?? user.l2
        let source = Source(id: UUID().uuidString, userId: user.id, orgId: orgId, type: .kindle, uri: "readwise://import/\(UUID().uuidString)", language: language, metaJSON: encodeMeta(readwise: highlights), firstSeenAt: Date(), lastIngestedAt: Date())
        sourceRepository.save(source)
        let cards = await cardCreationService.generateCards(user: user, source: source, transcript: nil, textBlocks: highlights.map { $0.text })
        return IngestionResult(source: source, transcript: nil, cards: cards)
    }

    private func encodeMeta(highlights: [KindleHighlight]) -> String {
        guard let data = try? JSONEncoder().encode(highlights), let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    private func encodeMeta(readwise: [ReadwiseHighlight]) -> String {
        guard let data = try? JSONEncoder().encode(readwise), let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    private func encodeMeta(subtitles: [SubtitleLine]) -> String {
        guard let data = try? JSONEncoder().encode(subtitles), let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }
}
