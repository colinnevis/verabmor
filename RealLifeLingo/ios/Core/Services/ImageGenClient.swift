import Foundation

public protocol ImageGenClient {
    func generate(for term: String, sense: String?, completion: @escaping (Result<ImageGenerationResult, Error>) -> Void)
}

public final class StubImageGenClient: ImageGenClient {
    private let placeholders: [String]

    public init(placeholders: [String] = StubImageGenClient.defaultPlaceholders) {
        self.placeholders = placeholders
    }

    public func generate(for term: String, sense: String?, completion: @escaping (Result<ImageGenerationResult, Error>) -> Void) {
        let idx = abs(term.hashValue) % placeholders.count
        let url = placeholders[idx]
        completion(.success(ImageGenerationResult(url: url)))
    }

    private static let defaultPlaceholders: [String] = [
        "https://picsum.photos/seed/lingo1/400/400",
        "https://picsum.photos/seed/lingo2/400/400",
        "https://picsum.photos/seed/lingo3/400/400",
        "https://picsum.photos/seed/lingo4/400/400",
        "https://picsum.photos/seed/lingo5/400/400",
        "https://picsum.photos/seed/lingo6/400/400",
        "https://picsum.photos/seed/lingo7/400/400",
        "https://picsum.photos/seed/lingo8/400/400",
        "https://picsum.photos/seed/lingo9/400/400",
        "https://picsum.photos/seed/lingo10/400/400"
    ]
}
