import SwiftUI

/// Відеопроповіді — відкриваються в YouTube.
struct VideoListView: View {
    var body: some View {
        List(LocalContent.videos) { video in
            Link(destination: video.watchURL) {
                HStack(spacing: 12) {
                    RemoteImage(url: video.thumbnailURL)
                        .frame(width: 128, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .black.opacity(0.4))
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                        if let day = video.day {
                            Text(day.parishDay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

/// Буклети (PDF), згруповані за темою.
struct BookletListView: View {
    private static let groupOrder = ["Таїнства", "Молитва", "Родина", "Парафія"]

    private struct BookletGroup: Identifiable {
        let id: String
        let booklets: [Booklet]
    }

    private var groups: [BookletGroup] {
        Dictionary(grouping: LocalContent.booklets) { $0.group ?? "Інше" }
            .sorted { lhs, rhs in
                let left = Self.groupOrder.firstIndex(of: lhs.key) ?? .max
                let right = Self.groupOrder.firstIndex(of: rhs.key) ?? .max
                return left == right ? lhs.key < rhs.key : left < right
            }
            .map { BookletGroup(id: $0.key, booklets: $0.value) }
    }

    var body: some View {
        List {
            ForEach(groups) { group in
                Section(group.id) {
                    ForEach(group.booklets) { booklet in
                        NavigationLink(value: booklet) {
                            Label {
                                Text(booklet.title)
                            } icon: {
                                Image(systemName: "doc.richtext")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
    }
}
