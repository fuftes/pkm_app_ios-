import SwiftUI

/// Показує markdown зі сторінок і проповідей: заголовки, абзаци, списки, цитати, лінії, зображення.
/// SwiftUI `Text` сам уміє лише «рядковий» markdown (жирний, курсив, посилання), тож блоки розбираємо тут.
struct MarkdownView: View {
    let blocks: [MarkdownBlock]

    init(_ markdown: String) {
        blocks = MarkdownBlock.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inline(text))
                .font(level <= 2 ? Font.title2.bold() : level == 3 ? Font.title3.bold() : Font.headline)
                .padding(.top, 6)
        case let .paragraph(text):
            Text(inline(text))
                .font(.body)
                .lineSpacing(3)
        case let .listItem(marker, text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(marker).foregroundStyle(.tint)
                Text(inline(text)).lineSpacing(3)
            }
        case let .quote(text):
            Text(inline(text))
                .italic()
                .lineSpacing(3)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.tint).frame(width: 3)
                }
        case .rule:
            Divider().padding(.vertical, 4)
        case let .image(url):
            RemoteImage(url: url, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

enum MarkdownBlock: Hashable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case listItem(marker: String, text: String)
    case quote(String)
    case rule
    case image(URL)

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            let text = paragraph.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { blocks.append(.paragraph(text)) }
            paragraph.removeAll()
        }

        for rawLine in markdown.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
            } else if line.hasPrefix("#") {
                flushParagraph()
                let level = line.prefix(while: { $0 == "#" }).count
                let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty { blocks.append(.heading(level: level, text: text)) }
            } else if line == "---" || line == "***" || line == "___" {
                flushParagraph()
                blocks.append(.rule)
            } else if let url = imageURL(in: line) {
                flushParagraph()
                blocks.append(.image(url))
            } else if line.hasPrefix("> ") || line == ">" {
                flushParagraph()
                blocks.append(.quote(String(line.dropFirst()).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                flushParagraph()
                blocks.append(.listItem(marker: "•", text: String(line.dropFirst(2))))
            } else if let dot = line.firstIndex(of: "."), dot > line.startIndex,
                      line[..<dot].allSatisfy(\.isNumber),
                      line[line.index(after: dot)...].hasPrefix(" ") {
                flushParagraph()
                blocks.append(.listItem(marker: String(line[...dot]),
                                        text: line[line.index(after: dot)...].trimmingCharacters(in: .whitespaces)))
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()
        return blocks
    }

    /// Рядок, що складається лише з `![…](url)`.
    private static func imageURL(in line: String) -> URL? {
        guard line.hasPrefix("!["), line.hasSuffix(")"),
              let open = line.range(of: "](") else { return nil }
        let urlString = line[open.upperBound..<line.index(before: line.endIndex)]
            .split(separator: " ").first.map(String.init) ?? ""
        return URL(string: urlString)
    }
}
