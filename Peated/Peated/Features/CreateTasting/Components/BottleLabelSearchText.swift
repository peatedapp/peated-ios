import Foundation

enum BottleLabelSearchText {
    struct Observation: Equatable {
        let text: String
        let x: Double
        let y: Double
    }

    static func query(
        from observations: [Observation],
        maximumLines: Int = 4,
        maximumCharacters: Int = 120
    ) -> String {
        guard maximumLines > 0, maximumCharacters > 0 else { return "" }

        let sortedLines = observations
            .flatMap(expandedLines)
            .sorted {
                if abs($0.y - $1.y) > 1 {
                    return $0.y < $1.y
                }
                return $0.x < $1.x
            }

        var seen = Set<String>()
        var lines: [String] = []

        for observation in sortedLines {
            let line = normalizedLine(observation.text)
            guard !line.isEmpty, line.contains(where: { $0.isLetter || $0.isNumber }) else {
                continue
            }

            let comparisonKey = line.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            guard seen.insert(comparisonKey).inserted else { continue }

            let proposedQuery = (lines + [line]).joined(separator: " ")
            if proposedQuery.count > maximumCharacters {
                continue
            }

            lines.append(line)
            if lines.count == maximumLines {
                break
            }
        }

        return lines.joined(separator: " ")
    }

    private static func expandedLines(_ observation: Observation) -> [Observation] {
        observation.text
            .components(separatedBy: .newlines)
            .enumerated()
            .map { index, text in
                Observation(
                    text: text,
                    x: observation.x,
                    y: observation.y + Double(index) * 0.01
                )
            }
    }

    private static func normalizedLine(_ line: String) -> String {
        line
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
