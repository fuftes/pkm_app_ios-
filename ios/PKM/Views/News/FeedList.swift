import SwiftUI

/// Список записів одного джерела з «потягни, щоб оновити» і довантаженням у кінці.
/// Перехід на запис — через `navigationDestination(for: FeedItem.self)` у батьківському стеку.
struct FeedList: View {
    let loader: FeedLoader

    var body: some View {
        List {
            ForEach(loader.items) { item in
                NavigationLink(value: item) {
                    FeedItemRow(item: item)
                }
                .task { await loader.loadMore(ifNeededFor: item) }
            }

            if loader.isLoading && !loader.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .overlay {
            if loader.items.isEmpty {
                if loader.isLoading {
                    ProgressView()
                } else if let message = loader.errorMessage {
                    ContentUnavailableView {
                        Label("Немає з'єднання", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Оновити") { Task { await loader.refresh() } }
                    }
                } else {
                    ContentUnavailableView("Поки що порожньо", systemImage: "tray")
                }
            }
        }
        .refreshable { await loader.refresh() }
        .task { await loader.loadIfNeeded() }
    }
}

struct FeedItemRow: View {
    let item: FeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(3)
                if !item.excerpt.isEmpty {
                    Text(item.excerpt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let date = item.date {
                    Text(date.parishDay)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let imageURL = item.imageURL {
                RemoteImage(url: imageURL)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 4)
    }
}
