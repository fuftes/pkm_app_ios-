import SwiftUI

/// Вкладка «Читання»: вісник, статті, проповіді, відео, буклети.
struct ReadingView: View {
    enum ReadingSection: String, CaseIterable, Identifiable {
        case all, visnyk, articles, sermons, videos, booklets, answers

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: "Усе"
            case .visnyk: "Вісник"
            case .articles: "Статті"
            case .sermons: "Проповіді"
            case .videos: "Відео"
            case .booklets: "Буклети"
            case .answers: "Відповіді"
            }
        }

        var feed: FeedSource? {
            switch self {
            case .all: .allReading
            case .visnyk: .visnyk
            case .articles: .articles
            case .answers: .answers
            case .sermons, .videos, .booklets: nil
            }
        }
    }

    @State private var selection: ReadingSection = .all
    @State private var loaders: [ReadingSection: FeedLoader] = Dictionary(uniqueKeysWithValues:
        ReadingSection.allCases.compactMap { section in section.feed.map { (section, FeedLoader(source: $0)) } })

    var body: some View {
        NavigationStack {
            content
                .id(selection)
                .chipBar(ReadingSection.allCases.map { Chip(id: $0, title: $0.title) }, selection: $selection)
                .navigationTitle("Читання")
                .navigationDestination(for: FeedItem.self) { PostDetailView(item: $0) }
                .navigationDestination(for: Sermon.self) { SermonDetailView(sermon: $0) }
                .navigationDestination(for: Booklet.self) { PDFScreen(title: $0.title, url: $0.url) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .sermons:
            SermonListView()
        case .videos:
            VideoListView()
        case .booklets:
            BookletListView()
        default:
            if let loader = loaders[selection] {
                FeedList(loader: loader)
            }
        }
    }
}
