import Foundation

/// Один запис у стрічці (новина, стаття, випуск вісника) — незалежно від джерела.
struct FeedItem: Identifiable, Hashable {
    enum Body: Hashable {
        /// Повний текст довантажується з WordPress за id.
        case wordpress(base: URL, postID: Int)
        /// Текст уже є (наприклад, з RSS).
        case html(String)
    }

    let id: String
    let title: String
    let date: Date?
    let excerpt: String
    let imageURL: URL?
    let link: URL?
    let body: Body
}

extension FeedItem {
    init(post: WPPost, base: URL) {
        self.init(
            id: "wp-\(post.id)",
            title: post.title.rendered.htmlStrippedAndDecoded,
            date: post.publishedAt,
            excerpt: (post.excerpt?.rendered ?? "").htmlStrippedAndDecoded,
            imageURL: post.featuredImageURL,
            link: URL(string: post.link),
            body: .wordpress(base: base, postID: post.id)
        )
    }
}
