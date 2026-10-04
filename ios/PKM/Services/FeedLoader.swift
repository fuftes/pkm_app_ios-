import Foundation
import Observation

/// Стрічка з посторінковим довантаженням для одного `FeedSource`.
@MainActor
@Observable
final class FeedLoader {
    let source: FeedSource

    private(set) var items: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var canLoadMore = true

    private var nextPage = 1

    init(source: FeedSource) {
        self.source = source
    }

    func loadIfNeeded() async {
        guard items.isEmpty, !isLoading else { return }
        await refresh()
    }

    func refresh() async {
        nextPage = 1
        canLoadMore = true
        await load(reset: true)
    }

    /// Викликати, коли на екрані з'являється `item`: біля кінця списку довантажуємо далі.
    func loadMore(ifNeededFor item: FeedItem) async {
        guard canLoadMore, !isLoading,
              let index = items.firstIndex(of: item), index >= items.count - 5 else { return }
        await load(reset: false)
    }

    private func load(reset: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [FeedItem]
            switch source.kind {
            case let .wordpress(base, categories):
                let page = try await WordPressClient(base: base).posts(categories: categories, page: nextPage)
                fetched = page.posts.map { FeedItem(post: $0, base: base) }
                canLoadMore = nextPage < page.totalPages
                nextPage += 1
            case let .rss(url):
                fetched = try await RSSClient().items(from: url)
                canLoadMore = false
            }
            errorMessage = nil
            if reset {
                items = fetched
            } else {
                let known = Set(items.map(\.id))
                items += fetched.filter { !known.contains($0.id) }
            }
        } catch is CancellationError {
            // Екран закрили — нічого не робимо.
        } catch let error as URLError where error.code == .cancelled {
            // Те саме для URLSession.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
