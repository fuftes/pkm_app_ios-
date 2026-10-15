import Foundation

/// Markdown-файл зі «шапкою» (`---` … `---`), як у `pages/*.md` і `sermons/*.md`.
struct PageDocument {
    let fields: [String: String]
    let lists: [String: [String]]
    let body: String

    var title: String { fields["title"] ?? "" }
    /// `ok` / `thin` / `empty` — див. README репозиторію змісту.
    var status: String { fields["status"] ?? "ok" }
    var isEmpty: Bool { status == "empty" }

    init(markdown: String) {
        var fields: [String: String] = [:]
        var lists: [String: [String]] = [:]
        var body = markdown

        let lines = markdown.components(separatedBy: "\n")
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
            for line in lines[1..<end] {
                guard let colon = line.firstIndex(of: ":") else { continue }
                let key = line[..<colon].trimmingCharacters(in: .whitespaces)
                let raw = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                if raw.hasPrefix("["), let array = PageDocument.decodeJSON([String].self, raw) {
                    lists[key] = array
                } else if raw.hasPrefix("\""), let string = PageDocument.decodeJSON(String.self, raw) {
                    fields[key] = string
                } else {
                    fields[key] = raw
                }
            }
            body = lines[(end + 1)...].joined(separator: "\n")
        }

        self.fields = fields
        self.lists = lists
        self.body = PageDocument.removingLeadingTitle(body)
    }

    private static func decodeJSON<T: Decodable>(_ type: T.Type, _ raw: String) -> T? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Перший заголовок `# …` дублює назву екрана — прибираємо його.
    private static func removingLeadingTitle(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeFirst()
        }
        if let first = lines.first, first.hasPrefix("# ") {
            lines.removeFirst()
        }
        return lines.joined(separator: "\n")
    }
}
