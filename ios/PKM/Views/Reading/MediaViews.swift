import SwiftUI
import UIKit

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

/// Буклети (PDF) у два стовпчики з обкладинками, згруповані за темою.
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

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.id)
                            .font(.title3.bold())
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                            ForEach(group.booklets) { booklet in
                                NavigationLink(value: booklet) {
                                    BookletCard(booklet: booklet)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

private struct BookletCard: View {
    let booklet: Booklet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookletCover(fileURL: booklet.coverFileURL)
                .aspectRatio(0.62, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.black.opacity(0.08))
                }
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            Text(booklet.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }
}

/// Обкладинка з бандла; обрізається зверху, щоб завжди було видно назву.
private struct BookletCover: View {
    let fileURL: URL?

    var body: some View {
        Color(.secondarySystemBackground)
            .overlay(alignment: .top) {
                if let fileURL, let image = UIImage(contentsOfFile: fileURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
                }
            }
            .clipped()
    }
}
