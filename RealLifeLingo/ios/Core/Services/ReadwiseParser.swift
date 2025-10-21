import Foundation

public struct ReadwiseHighlight: Codable {
    public let title: String
    public let author: String
    public let text: String
    public let note: String
    public let tags: [String]
    public let highlightedAt: Date?
}

public final class ReadwiseParser {
    private let isoFormatter = ISO8601DateFormatter()

    public init() {}

    public func parseCSV(data: Data) -> [ReadwiseHighlight] {
        guard let string = String(data: data, encoding: .utf8) else { return [] }
        let lines = string.components(separatedBy: .newlines)
        guard let header = lines.first else { return [] }
        let columns = header.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var highlights: [ReadwiseHighlight] = []
        for line in lines.dropFirst() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let values = splitCSV(line: line)
            var dict: [String: String] = [:]
            for (col, value) in zip(columns, values) {
                dict[col] = value
            }
            let highlight = ReadwiseHighlight(
                title: dict["title"] ?? "",
                author: dict["author"] ?? "",
                text: dict["highlight"] ?? dict["text"] ?? "",
                note: dict["note"] ?? "",
                tags: dict["tags"].map { $0.components(separatedBy: "|") } ?? [],
                highlightedAt: dict["highlighted_at"].flatMap { isoFormatter.date(from: $0) }
            )
            highlights.append(highlight)
        }
        return highlights
    }

    public func parseJSON(data: Data) -> [ReadwiseHighlight] {
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else { return [] }
        var highlights: [ReadwiseHighlight] = []
        for item in array {
            let tags = (item["tags"] as? [String]) ?? []
            let dateString = item["highlighted_at"] as? String
            let highlight = ReadwiseHighlight(
                title: item["title"] as? String ?? "",
                author: item["author"] as? String ?? "",
                text: item["text"] as? String ?? "",
                note: item["note"] as? String ?? "",
                tags: tags,
                highlightedAt: dateString.flatMap { isoFormatter.date(from: $0) }
            )
            highlights.append(highlight)
        }
        return highlights
    }

    private func splitCSV(line: String) -> [String] {
        var results: [String] = []
        var current = ""
        var insideQuotes = false
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                results.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            results.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return results
    }
}
