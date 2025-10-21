import Foundation

public final class CardCreationService {
    private let nlpService: NLPService
    private let imageClient: ImageGenClient
    private let llmClient: LLMClient
    private let dictionaryService: LocalDictionaryService
    private let cardRepository: CardRepositoryType
    private let usageRepository: UsageEventRepositoryType
    private let eventProcessor: UsageEventProcessing

    public init(nlpService: NLPService,
                imageClient: ImageGenClient,
                llmClient: LLMClient,
                dictionaryService: LocalDictionaryService,
                cardRepository: CardRepositoryType,
                usageRepository: UsageEventRepositoryType,
                eventProcessor: UsageEventProcessing) {
        self.nlpService = nlpService
        self.imageClient = imageClient
        self.llmClient = llmClient
        self.dictionaryService = dictionaryService
        self.cardRepository = cardRepository
        self.usageRepository = usageRepository
        self.eventProcessor = eventProcessor
    }

    public func generateCards(user: UserProfile, source: Source, transcript: Transcript?, textBlocks: [String] = [], limit: Int = 30) async -> [Card] {
        var corpus = textBlocks
        if let transcript = transcript {
            corpus.append(contentsOf: transcript.segments.map { $0.text })
        }
        let combined = corpus.joined(separator: " ")
        let language = source.language ?? nlpService.detectLanguage(for: combined) ?? user.l2
        let existingCards = Set(cardRepository.cards(for: user.id).map { $0.l2Text.lowercased() })
        let candidates = extractCandidates(from: corpus, segments: transcript?.segments, language: language, existing: existingCards)
        let sorted = rankCandidates(candidates: candidates)
        let selected = Array(sorted.prefix(limit))
        var cards: [Card] = []
        for candidate in selected {
            let examples = findExamples(for: candidate.term, in: corpus)
            let exampleL2 = await bestExample(for: candidate.term, examples: examples, language: language)
            let gloss = await glossForTerm(candidate.term, language: language)
            let pos = nlpService.partOfSpeech(for: candidate.term, language: language) ?? "noun"
            let cefr = estimateCEFR(for: candidate.term, language: language, frequency: candidate.frequency)
            let imageURL = await imageURLForTerm(candidate.term)
            let tags = buildTags(source: source, candidate: candidate)
            let card = Card(
                id: UUID().uuidString,
                userId: user.id,
                sourceType: source.type,
                sourceId: source.id,
                sourceLoc: transcript?.segments.first { $0.text.lowercased().contains(candidate.term.lowercased()) }.map { "\($0.start)" },
                l1Text: gloss,
                l2Text: candidate.term,
                gloss: gloss,
                pos: pos,
                cefr: cefr,
                imageURL: imageURL,
                audioURL: nil,
                exampleL2: exampleL2.l2,
                exampleL1: exampleL2.l1,
                tags: tags,
                createdAt: Date(),
                strength: 0,
                ease: 2.5,
                nextDueAt: nil
            )
            cardRepository.save(card)
            let event = UsageEvent(id: UUID().uuidString, userId: user.id, orgId: source.orgId, type: .aiGenerate, createdAt: Date(), payloadJSON: "{\"term\":\"\(candidate.term)\"}")
            usageRepository.save(event)
            eventProcessor.process(event: event)
            cards.append(card)
        }
        return cards
    }

    private func extractCandidates(from sentences: [String], segments: [TranscriptSegment]?, language: String?, existing: Set<String>) -> [CardExtractionCandidate] {
        var frequency: [String: Int] = [:]
        var collocations: [String: Int] = [:]
        let starredSentences = segments?.filter { $0.isStarred }.map { $0.text.lowercased() } ?? []
        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            let tokens = nlpService.tokens(in: lowerSentence, language: language).filter { $0.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ-]", options: .regularExpression) != nil }
            let lemmas = nlpService.lemmas(for: tokens, language: language)
            for lemma in lemmas {
                guard lemma.count > 1 else { continue }
                frequency[lemma, default: 0] += 1
            }
            let bigrams = zip(tokens, tokens.dropFirst()).map { "\($0) \($1)" }
            for bigram in bigrams {
                collocations[bigram, default: 0] += 1
            }
        }
        var candidates: [CardExtractionCandidate] = []
        for (lemma, freq) in frequency {
            let novelty = existing.contains(lemma) ? 0.1 : 1.0
            let isStarred = starredSentences.contains { $0.contains(lemma) }
            candidates.append(CardExtractionCandidate(term: lemma, frequency: freq, novelty: novelty, isStarred: isStarred, examples: sentences.filter { $0.lowercased().contains(lemma) }))
        }
        for (collocation, freq) in collocations where freq > 1 {
            let novelty = existing.contains(collocation) ? 0.1 : 1.2
            let isStarred = starredSentences.contains { $0.contains(collocation) }
            candidates.append(CardExtractionCandidate(term: collocation, frequency: freq, novelty: novelty, isStarred: isStarred, examples: sentences.filter { $0.lowercased().contains(collocation) }))
        }
        return candidates
    }

    private func rankCandidates(candidates: [CardExtractionCandidate]) -> [CardExtractionCandidate] {
        return candidates.sorted { lhs, rhs in
            let lhsScore = Double(lhs.frequency) * lhs.novelty + (lhs.isStarred ? 5 : 0)
            let rhsScore = Double(rhs.frequency) * rhs.novelty + (rhs.isStarred ? 5 : 0)
            return lhsScore > rhsScore
        }
    }

    private func findExamples(for term: String, in sentences: [String]) -> [String] {
        return sentences.filter { $0.lowercased().contains(term.lowercased()) }
    }

    private func bestExample(for term: String, examples: [String], language: String?) async -> ExampleResult {
        if let sample = examples.first {
            return ExampleResult(l2: sample, l1: dictionaryService.lookup(term: term, language: language) ?? sample)
        }
        return await withCheckedContinuation { continuation in
            llmClient.rewrite(sentence: "Use \(term) in a sentence.") { result in
                switch result {
                case .success(let sentence):
                    continuation.resume(returning: ExampleResult(l2: sentence, l1: sentence))
                case .failure:
                    continuation.resume(returning: ExampleResult(l2: term, l1: term))
                }
            }
        }
    }

    private func glossForTerm(_ term: String, language: String?) async -> String {
        if let gloss = dictionaryService.lookup(term: term, language: language) {
            return gloss
        }
        return await withCheckedContinuation { continuation in
            llmClient.verify(gloss: term, for: term) { result in
                continuation.resume(returning: (try? result.get()) ?? term)
            }
        }
    }

    private func imageURLForTerm(_ term: String) async -> String {
        await withCheckedContinuation { continuation in
            imageClient.generate(for: term, sense: nil) { result in
                continuation.resume(returning: (try? result.get().url) ?? "https://picsum.photos/seed/placeholder/400/400")
            }
        }
    }

    private func estimateCEFR(for term: String, language: String?, frequency: Int) -> String {
        if frequency > 5 { return "A2" }
        if term.count > 12 { return "C1" }
        if term.contains(" ") { return "B1" }
        return "B2"
    }

    private func buildTags(source: Source, candidate: CardExtractionCandidate) -> [String] {
        var tags = [source.type.rawValue]
        if let lang = source.language { tags.append(lang) }
        if candidate.term.contains(" ") { tags.append("phrase") }
        return tags
    }
}
