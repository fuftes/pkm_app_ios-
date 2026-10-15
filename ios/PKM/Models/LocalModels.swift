import Foundation

/// Проповідь зі `sermons.json` (без тексту — текст у `sermons/*.md`).
struct Sermon: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let date: String
    let preacher: String
    let videos: [String]
    let minutes: Int
    let file: String
    let words: Int

    var day: Date? { LocalDate.parse(date) }
}

/// Відео з `videos.json`.
struct SermonVideo: Decodable, Identifiable, Hashable {
    let youtubeID: String
    let title: String
    let date: String
    let preacher: String
    let sermon: String?

    var id: String { youtubeID }
    var day: Date? { LocalDate.parse(date) }
    var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(youtubeID)")! }
    var thumbnailURL: URL { URL(string: "https://i.ytimg.com/vi/\(youtubeID)/hqdefault.jpg")! }

    enum CodingKeys: String, CodingKey {
        case youtubeID = "youtube_id"
        case title, date, preacher, sermon
    }
}

/// Буклет з `documents.json`.
struct Booklet: Decodable, Identifiable, Hashable {
    let file: String
    let title: String
    let group: String?
    let colored: String?
    /// Обкладинка (`booklets/covers/*.jpg`) — вшита в застосунок як папка `covers`.
    let cover: String?

    var id: String { file }
    /// Кольорова версія, якщо є, інакше звичайна.
    var url: URL { AppConfig.contentURL(colored ?? file) }

    var coverFileURL: URL? {
        guard let cover else { return nil }
        return Bundle.main.resourceURL?
            .appendingPathComponent("covers")
            .appendingPathComponent((cover as NSString).lastPathComponent)
    }
}

/// Фото з `gallery.json`.
struct GalleryPhoto: Decodable, Identifiable, Hashable {
    let file: String
    let caption: String

    var id: String { file }
    var url: URL { AppConfig.contentURL(file) }
}

struct Gallery: Decodable {
    let outside: [GalleryPhoto]
    let inside: [GalleryPhoto]

    static let empty = Gallery(outside: [], inside: [])
}

/// Тижневий розклад з `schedule.json`. Ключі днів: "0" — неділя … "6" — субота.
struct WeekSchedule: Decodable {
    let week: [String: [Service]]

    static let empty = WeekSchedule(week: [:])

    struct Service: Decodable, Hashable {
        let time: String
        let title: String
        let kind: String

        /// У файлі служба записана масивом: ["09:00", "Божественна Літургія", "liturgy"].
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            time = try container.decode(String.self)
            title = try container.decode(String.self)
            kind = (try? container.decode(String.self)) ?? "other"
        }

        init(time: String, title: String, kind: String) {
            self.time = time
            self.title = title
            self.kind = kind
        }

        var minutesFromMidnight: Int {
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return 0 }
            return parts[0] * 60 + parts[1]
        }
    }

    /// Служби на день; `weekday` — як у Calendar (1 — неділя … 7 — субота).
    func services(weekday: Int) -> [Service] {
        (week[String(weekday - 1)] ?? []).sorted { $0.minutesFromMidnight < $1.minutesFromMidnight }
    }

    /// Найближча служба від `date` (у межах наступного тижня).
    func nextService(after date: Date = .now, calendar: Calendar = .kyiv) -> (date: Date, service: Service)? {
        let startOfToday = calendar.startOfDay(for: date)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            for service in services(weekday: weekday) {
                guard let start = calendar.date(byAdding: .minute, value: service.minutesFromMidnight, to: day) else { continue }
                if start > date { return (start, service) }
            }
        }
        return nil
    }
}

enum LocalDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(_ string: String) -> Date? { formatter.date(from: string) }
}

extension Calendar {
    /// Григоріанський календар у київському часі, тиждень з понеділка.
    static let kyiv: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Kyiv") ?? .current
        calendar.locale = Locale(identifier: "uk_UA")
        calendar.firstWeekday = 2
        return calendar
    }()
}
