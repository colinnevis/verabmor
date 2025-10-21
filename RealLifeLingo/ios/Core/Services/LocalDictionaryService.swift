import Foundation

struct DictionaryEntry: Codable {
    let term: String
    let gloss: String
}

public final class LocalDictionaryService {
    private let entries: [String: String]

    public init() {
        if let url = Bundle.main.url(forResource: "LocalDict", withExtension: "json") ?? Bundle(for: LocalDictionaryService.self).url(forResource: "LocalDict", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([DictionaryEntry].self, from: data) {
            entries = Dictionary(uniqueKeysWithValues: decoded.map { ($0.term.lowercased(), $0.gloss) })
        } else {
            entries = [
                "hola": "hello",
                "gracias": "thank you",
                "bonjour": "hello",
                "merci": "thank you",
                "agua": "water"
            ]
        }
    }

    public func lookup(term: String, language: String?) -> String? {
        return entries[term.lowercased()]
    }
}
