import XCTest
@testable import RealLifeLingo

final class KindleParserTests: XCTestCase {
    func testParsesHighlights() {
        let parser = KindleParser()
        let sample = """
        Book Title (Author)
        - Your Highlight on Location 123 | Added on Monday, January 1, 2024 8:00:00 AM
        Esto es una prueba.
        ==========
        """.data(using: .utf8)!
        let highlights = parser.parse(data: sample)
        XCTAssertEqual(highlights.count, 1)
        XCTAssertEqual(highlights.first?.text, "Esto es una prueba.")
    }
}
