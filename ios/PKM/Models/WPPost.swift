import Foundation

/// Запис із /wp-json/wp/v2/posts.
struct WPPost: Decodable {
    struct Rendered: Decodable {
        let rendered: String
    }

    let id: Int
    let date: String
    let link: String
    let title: Rendered
    let excerpt: Rendered?
    let content: Rendered?
    let categories: [Int]?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id, date, link, title, excerpt, content, categories
        case embedded = "_embedded"
    }

    var publishedAt: Date? { WPPost.dateFormatter.date(from: date) }

    var featuredImageURL: URL? {
        guard let media = embedded?.featuredMedia?.first else { return nil }
        let sizes = media.sizes
        let best = sizes["medium_large"] ?? sizes["large"] ?? sizes["medium"] ?? media.sourceURL
        return best.flatMap(URL.init(string:))
    }

    /// WordPress віддає дату без часового поясу — це київський час.
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

extension WPPost {
    struct Embedded: Decodable {
        let featuredMedia: [Media]?

        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            featuredMedia = try? container.decode([Media].self, forKey: .featuredMedia)
        }
    }

    /// Медіафайл. Декодуємо «поблажливо»: WordPress інколи віддає помилку або `[]` замість об'єкта.
    struct Media: Decodable {
        let sourceURL: String?
        let sizes: [String: String]

        private struct Details: Decodable {
            let sizes: [String: Size]?
        }

        private struct Size: Decodable {
            let source_url: String
        }

        enum CodingKeys: String, CodingKey {
            case sourceURL = "source_url"
            case mediaDetails = "media_details"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sourceURL = try? container.decode(String.self, forKey: .sourceURL)
            let details = try? container.decode(Details.self, forKey: .mediaDetails)
            sizes = (details?.sizes ?? [:]).mapValues(\.source_url)
        }
    }
}
