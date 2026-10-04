import Foundation

extension String {
    /// Прибирає HTML-теги й розшифровує сутності (`&#8220;`, `&amp;` …) — для заголовків і анонсів.
    var htmlStrippedAndDecoded: String {
        var result = ""
        result.reserveCapacity(count)
        var insideTag = false
        for character in self {
            if character == "<" {
                insideTag = true
            } else if character == ">" && insideTag {
                insideTag = false
                result.append(" ")
            } else if !insideTag {
                result.append(character)
            }
        }
        return result.decodingHTMLEntities
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    var decodingHTMLEntities: String {
        guard contains("&") else { return self }
        var result = ""
        var index = startIndex
        while index < endIndex {
            if self[index] == "&",
               let semicolon = self[index...].prefix(12).firstIndex(of: ";"),
               let decoded = String.decodeEntity(String(self[self.index(after: index)..<semicolon])) {
                result.append(decoded)
                index = self.index(after: semicolon)
            } else {
                result.append(self[index])
                index = self.index(after: index)
            }
        }
        return result
    }

    private static let namedEntities: [String: Character] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "hellip": "…", "ndash": "–", "mdash": "—", "laquo": "«", "raquo": "»",
        "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”", "bdquo": "„", "copy": "©",
    ]

    private static func decodeEntity(_ name: String) -> Character? {
        if name.hasPrefix("#x") || name.hasPrefix("#X") {
            return UInt32(name.dropFirst(2), radix: 16).flatMap { Unicode.Scalar($0) }.map { Character($0) }
        }
        if name.hasPrefix("#") {
            return UInt32(name.dropFirst(), radix: 10).flatMap { Unicode.Scalar($0) }.map { Character($0) }
        }
        return namedEntities[name]
    }
}
