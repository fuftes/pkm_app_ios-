import SwiftUI

/// Повний текст запису (новина, стаття, вісник).
struct PostDetailView: View {
    let item: FeedItem

    @State private var html: String?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let html {
                HTMLArticleView(title: item.title, subtitle: item.date?.parishDay, html: html)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Не вдалося відкрити", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Спробувати ще") { Task { await load() } }
                }
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let link = item.link {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: link, subject: Text(item.title))
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        errorMessage = nil
        switch item.body {
        case let .html(text):
            html = text
        case let .wordpress(base, postID):
            do {
                html = try await WordPressClient(base: base).post(id: postID).content?.rendered ?? ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
