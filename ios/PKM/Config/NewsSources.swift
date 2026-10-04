import Foundation

/// Джерело стрічки: рубрика(и) WordPress або будь-який RSS-канал.
struct FeedSource: Identifiable, Hashable {
    enum Kind: Hashable {
        case wordpress(base: URL, categories: [Int])
        case rss(URL)
    }

    let id: String
    let title: String
    let kind: Kind
}

extension FeedSource {
    // MARK: Новини

    static let allNews = FeedSource(
        id: "news-all", title: "Усі",
        kind: .wordpress(base: AppConfig.siteURL,
                         categories: [WPCategory.parishNews, WPCategory.ugccNews, WPCategory.uncategorized]))

    static let parishNews = FeedSource(
        id: "news-parish", title: "Парафія",
        kind: .wordpress(base: AppConfig.siteURL, categories: [WPCategory.parishNews]))

    static let ugccNews = FeedSource(
        id: "news-ugcc", title: "УГКЦ",
        kind: .wordpress(base: AppConfig.siteURL, categories: [WPCategory.ugccNews]))

    /// Вкладки (чипи) у розділі «Новини». Щоб додати нове джерело — допишіть сюди, наприклад:
    ///
    ///     FeedSource(id: "vatican", title: "Ватикан",
    ///                kind: .rss(URL(string: "https://www.vaticannews.va/uk.rss.xml")!))
    ///
    /// або іншу рубрику цього ж сайту: `.wordpress(base: AppConfig.siteURL, categories: [id])`.
    static let newsTab: [FeedSource] = [.allNews, .parishNews, .ugccNews]

    // MARK: Читання

    static let allReading = FeedSource(
        id: "read-all", title: "Усе",
        kind: .wordpress(base: AppConfig.siteURL,
                         categories: [WPCategory.visnyk, WPCategory.articles, WPCategory.answers, WPCategory.spiritual]))

    static let visnyk = FeedSource(
        id: "read-visnyk", title: "Вісник",
        kind: .wordpress(base: AppConfig.siteURL, categories: [WPCategory.visnyk]))

    static let articles = FeedSource(
        id: "read-articles", title: "Статті",
        kind: .wordpress(base: AppConfig.siteURL, categories: [WPCategory.articles]))

    static let answers = FeedSource(
        id: "read-answers", title: "Відповіді",
        kind: .wordpress(base: AppConfig.siteURL, categories: [WPCategory.answers]))
}
