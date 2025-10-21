import Foundation
import NaturalLanguage

public protocol NLPService {
    func detectLanguage(for text: String) -> String?
    func sentences(in text: String, language: String?) -> [String]
    func tokens(in text: String, language: String?) -> [String]
    func lemmas(for tokens: [String], language: String?) -> [String]
    func partOfSpeech(for token: String, language: String?) -> String?
}

public final class AppleNLPService: NLPService {
    public init() {}

    public func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    public func sentences(in text: String, language: String?) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        if let lang = language {
            tokenizer.setLanguage(NLLanguage(rawValue: lang))
        }
        var results: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                results.append(sentence)
            }
            return true
        }
        return results
    }

    public func tokens(in text: String, language: String?) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        if let lang = language {
            tokenizer.setLanguage(NLLanguage(rawValue: lang))
        }
        var results: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                results.append(token)
            }
            return true
        }
        return results
    }

    public func lemmas(for tokens: [String], language: String?) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        if let lang = language {
            tagger.setLanguage(NLLanguage(rawValue: lang), range: nil)
        }
        return tokens.map { token in
            tagger.string = token
            let range = token.startIndex..<token.endIndex
            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0?.rawValue
            return lemma ?? token.lowercased()
        }
    }

    public func partOfSpeech(for token: String, language: String?) -> String? {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        if let lang = language {
            tagger.setLanguage(NLLanguage(rawValue: lang), range: nil)
        }
        tagger.string = token
        let tag = tagger.tag(at: token.startIndex, unit: .word, scheme: .lexicalClass).0
        return tag?.rawValue
    }
}
