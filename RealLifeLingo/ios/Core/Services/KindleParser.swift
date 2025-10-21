import Foundation

public struct KindleHighlight: Codable {
    public let title: String
    public let location: String
    public let text: String
    public let addedOn: Date?
}

public final class KindleParser {
    private let dateFormatter: DateFormatter

    public init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy h:mm:ss a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = formatter
    }

    public func parse(data: Data) -> [KindleHighlight] {
        guard let string = String(data: data, encoding: .utf8) else { return [] }
        let entries = string.components(separatedBy: "==========").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var highlights: [KindleHighlight] = []
        for entry in entries where !entry.isEmpty {
            let lines = entry.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }
            let title = lines[0]
            let meta = lines[1]
            let text = lines.dropFirst(2).joined(separator: " ")
            let location = meta.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) ?? ""
            let dateString = meta.components(separatedBy: "Added on").last?.trimmingCharacters(in: .whitespaces)
            let addedOn = dateString.flatMap { dateFormatter.date(from: $0) }
            highlights.append(KindleHighlight(title: title, location: location, text: text, addedOn: addedOn))
        }
        return highlights
    }
}
