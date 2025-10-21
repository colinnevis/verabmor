import Foundation

public protocol LLMClient {
    func rewrite(sentence: String, completion: @escaping (Result<String, Error>) -> Void)
    func verify(gloss: String, for term: String, completion: @escaping (Result<String, Error>) -> Void)
}

public final class StubLLMClient: LLMClient {
    public init() {}

    public func rewrite(sentence: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(sentence))
    }

    public func verify(gloss: String, for term: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(gloss))
    }
}
