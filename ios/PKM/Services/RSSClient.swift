import Foundation

/// Простий читач RSS 2.0 — для сторонніх джерел новин (див. `FeedSource.newsTab`).
struct RSSClient {
    var session: URLSession = .shared

    func items(from url: URL) async throws -> [FeedItem] {
        let (data, _) = try await session.data(from: url)
        let parser = RSSParser(data: data)
        return parser.parse()
    }
}

private final class RSSParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var items: [FeedItem] = []
    private var current: [String: String] = [:]
    private var imageURL: String?
    private var text = ""
    private var insideItem = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> [FeedItem] {
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String] = [:]) {
        text = ""
        if elementName == "item" {
            insideItem = true
            current = [:]
            imageURL = nil
        } else if insideItem, ["enclosure", "media:content", "media:thumbnail"].contains(elementName),
                  imageURL == nil, let url = attributes["url"] {
            imageURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        guard insideItem else { return }
        if elementName == "item" {
            insideItem = false
            let html = current["content:encoded"] ?? current["description"] ?? ""
            let link = current["link"].flatMap(URL.init(string:))
            items.append(FeedItem(
                id: "rss-" + (current["guid"] ?? current["link"] ?? UUID().uuidString),
                title: (current["title"] ?? "").htmlStrippedAndDecoded,
                date: current["pubDate"].flatMap(RSSParser.dateFormatter.date(from:)),
                excerpt: (current["description"] ?? "").htmlStrippedAndDecoded,
                imageURL: imageURL.flatMap(URL.init(string:)),
                link: link,
                body: .html(html)
            ))
        } else {
            current[elementName] = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
