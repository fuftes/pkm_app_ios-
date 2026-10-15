import SwiftUI

/// Вкладка «Новини»: новини парафії, УГКЦ та інші джерела з `FeedSource.newsTab`.
struct NewsView: View {
    private let sources = FeedSource.newsTab
    @State private var selection = FeedSource.newsTab[0].id
    /// Завантажувач на кожне джерело живе весь час, щоб при перемиканні чипів не вантажити наново.
    @State private var loaders = Dictionary(uniqueKeysWithValues: FeedSource.newsTab.map { ($0.id, FeedLoader(source: $0)) })

    var body: some View {
        NavigationStack {
            FeedList(loader: loader(for: selection))
                .id(selection)
                .chipBar(sources.map { Chip(id: $0.id, title: $0.title) }, selection: $selection)
                .navigationTitle("Новини")
                .navigationDestination(for: FeedItem.self) { PostDetailView(item: $0) }
        }
    }

    private func loader(for id: String) -> FeedLoader {
        loaders[id] ?? loaders[sources[0].id]!
    }
}
