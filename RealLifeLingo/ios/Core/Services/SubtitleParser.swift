import Foundation

public struct SubtitleLine: Codable {
    public let index: Int
    public let start: TimeInterval
    public let end: TimeInterval
    public let text: String
}

public final class SubtitleParser {
    public init() {}

    public func parseSRT(data: Data) -> [SubtitleLine] {
        guard let string = String(data: data, encoding: .utf8) else { return [] }
        let blocks = string.components(separatedBy: "\r\n\r\n").flatMap { $0.components(separatedBy: "\n\n") }
        var lines: [SubtitleLine] = []
        for block in blocks {
            let parts = block.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard parts.count >= 3, let index = Int(parts[0]) else { continue }
            let times = parts[1].components(separatedBy: " --> ")
            guard times.count == 2 else { continue }
            let start = parseTimestamp(times[0])
            let end = parseTimestamp(times[1])
            let text = parts.dropFirst(2).joined(separator: " ")
            lines.append(SubtitleLine(index: index, start: start, end: end, text: text))
        }
        return lines.sorted { $0.index < $1.index }
    }

    public func parseVTT(data: Data) -> [SubtitleLine] {
        guard let string = String(data: data, encoding: .utf8) else { return [] }
        let lines = string.components(separatedBy: .newlines)
        var results: [SubtitleLine] = []
        var index = 0
        var currentText: [String] = []
        var currentStart: TimeInterval = 0
        var currentEnd: TimeInterval = 0
        for line in lines {
            if line.contains("-->") {
                let parts = line.components(separatedBy: " --> ")
                if parts.count == 2 {
                    currentStart = parseTimestamp(parts[0])
                    currentEnd = parseTimestamp(parts[1])
                    currentText = []
                    index += 1
                }
            } else if line.isEmpty {
                if !currentText.isEmpty {
                    results.append(SubtitleLine(index: index, start: currentStart, end: currentEnd, text: currentText.joined(separator: " ")))
                    currentText = []
                }
            } else if !line.hasPrefix("WEBVTT") {
                currentText.append(line)
            }
        }
        if !currentText.isEmpty {
            results.append(SubtitleLine(index: index, start: currentStart, end: currentEnd, text: currentText.joined(separator: " ")))
        }
        return results
    }

    private func parseTimestamp(_ string: String) -> TimeInterval {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.components(separatedBy: ":")
        guard parts.count >= 3 else { return 0 }
        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0
        return hours * 3600 + minutes * 60 + seconds
    }
}
