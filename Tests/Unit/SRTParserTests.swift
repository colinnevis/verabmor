import XCTest
@testable import RealLifeLingo

final class SRTParserTests: XCTestCase {
    func testParsesSRT() {
        let parser = SubtitleParser()
        let sample = """
        1
        00:00:01,000 --> 00:00:03,000
        Hola, ¿cómo estás?

        2
        00:00:04,000 --> 00:00:06,000
        Muy bien, gracias.
        """.data(using: .utf8)!
        let lines = parser.parseSRT(data: sample)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines.first?.text, "Hola, ¿cómo estás?")
    }
}
