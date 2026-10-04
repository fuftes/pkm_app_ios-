import SwiftUI

/// Усі проповіді (вшиті в застосунок) з пошуком за назвою та проповідником.
struct SermonListView: View {
    @State private var query = ""

    private var sermons: [Sermon] {
        let all = LocalContent.sermons
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.preacher.localizedCaseInsensitiveContains(query)
        }
    }

    /// Групуємо за роками — так легше гортати 100+ проповідей.
    private struct YearGroup: Identifiable {
        let id: String
        let sermons: [Sermon]
    }

    private var years: [YearGroup] {
        Dictionary(grouping: sermons) { String($0.date.prefix(4)) }
            .sorted { $0.key > $1.key }
            .map { YearGroup(id: $0.key, sermons: $0.value) }
    }

    var body: some View {
        List {
            ForEach(years) { group in
                Section(group.id) {
                    ForEach(group.sermons) { sermon in
                        NavigationLink(value: sermon) {
                            SermonRow(sermon: sermon)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "Пошук проповідей")
        .overlay {
            if sermons.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}

struct SermonRow: View {
    let sermon: Sermon

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sermon.title)
                .font(.headline)
                .lineLimit(3)
            HStack(spacing: 6) {
                if let day = sermon.day {
                    Text(day.parishDay)
                }
                if sermon.minutes > 0 {
                    Text("· \(sermon.minutes) хв")
                }
                if !sermon.videos.isEmpty {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct SermonDetailView: View {
    let sermon: Sermon

    var body: some View {
        let document = LocalContent.document(at: sermon.file)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let cover = document?.fields["cover"].flatMap(URL.init(string:)) {
                    RemoteImage(url: cover, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text(sermon.title)
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 2) {
                    Text(sermon.preacher)
                    if let day = sermon.day {
                        Text(day.parishDay)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let refs = document?.lists["refs"], !refs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(refs, id: \.self) { ref in
                                Label(ref, systemImage: "book.closed")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }

                ForEach(sermon.videos, id: \.self) { videoID in
                    if let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                        Link(destination: url) {
                            Label("Дивитися відео", systemImage: "play.rectangle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let text = document?.body {
                    MarkdownView(text)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let source = document?.fields["source"].flatMap(URL.init(string:)) {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: source, subject: Text(sermon.title))
                }
            }
        }
    }
}
