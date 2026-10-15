import Foundation

/// Зміст, вшитий у застосунок з кореня репозиторію (`pages/`, `sermons/`, `*.json`).
/// Папки додано в Xcode як folder references, тому в бандлі зберігається та сама структура.
enum LocalContent {
    static let sermons: [Sermon] = decode([Sermon].self, from: "sermons.json", fallback: [])
        .sorted { $0.date > $1.date }

    static let videos: [SermonVideo] = decode([SermonVideo].self, from: "videos.json", fallback: [])
        .sorted { $0.date > $1.date }

    static let booklets: [Booklet] = decode([Booklet].self, from: "documents.json", fallback: [])

    static let gallery: Gallery = decode(Gallery.self, from: "gallery.json", fallback: .empty)

    static let schedule: WeekSchedule = decode(WeekSchedule.self, from: "schedule.json", fallback: .empty)

    /// Сторінка з `pages/<slug>.md`.
    static func page(_ slug: String) -> PageDocument? {
        document(at: "pages/\(slug).md")
    }

    /// Будь-який markdown-файл за шляхом відносно кореня змісту (наприклад, `sermons/…md`).
    static func document(at relativePath: String) -> PageDocument? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent(relativePath),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return PageDocument(markdown: text)
    }

    static func sermon(file: String) -> Sermon? {
        sermons.first { $0.file == file }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from fileName: String, fallback: T) -> T {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Немає \(fileName) у бандлі")
            return fallback
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Не вдалося прочитати \(fileName): \(error)")
            return fallback
        }
    }
}
