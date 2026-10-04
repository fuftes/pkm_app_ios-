import Foundation

/// Мінімальний клієнт WordPress REST API (/wp-json/wp/v2).
struct WordPressClient {
    let base: URL
    var session: URLSession = .shared

    struct Page {
        let posts: [WPPost]
        let totalPages: Int
    }

    enum Failure: LocalizedError {
        case badResponse(Int)

        var errorDescription: String? {
            switch self {
            case .badResponse(let code): "Сайт відповів помилкою (\(code))."
            }
        }
    }

    /// Сторінка записів із заданих рубрик (без повного тексту — для списків).
    func posts(categories: [Int], page: Int, perPage: Int = 20, search: String? = nil) async throws -> Page {
        var query = [
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "_embed", value: "wp:featuredmedia"),
            URLQueryItem(name: "_fields", value: "id,date,link,title,excerpt,categories,_links,_embedded"),
        ]
        if !categories.isEmpty {
            query.append(URLQueryItem(name: "categories", value: categories.map(String.init).joined(separator: ",")))
        }
        if let search, !search.isEmpty {
            query.append(URLQueryItem(name: "search", value: search))
        }
        let (data, response) = try await get(path: "posts", query: query)
        let totalPages = Int(response.value(forHTTPHeaderField: "X-WP-TotalPages") ?? "") ?? page
        return Page(posts: try JSONDecoder().decode([WPPost].self, from: data), totalPages: totalPages)
    }

    /// Один запис з повним текстом.
    func post(id: Int) async throws -> WPPost {
        let query = [
            URLQueryItem(name: "_embed", value: "wp:featuredmedia"),
            URLQueryItem(name: "_fields", value: "id,date,link,title,excerpt,content,categories,_links,_embedded"),
        ]
        let (data, _) = try await get(path: "posts/\(id)", query: query)
        return try JSONDecoder().decode(WPPost.self, from: data)
    }

    private func get(path: String, query: [URLQueryItem]) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: base.appendingPathComponent("wp-json/wp/v2/\(path)"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        guard let http, (200..<300).contains(http.statusCode) else {
            throw Failure.badResponse(http?.statusCode ?? -1)
        }
        return (data, http)
    }
}
