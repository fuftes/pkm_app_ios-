import SwiftUI

/// Екран статичної сторінки з `pages/<slug>.md`.
struct PageScreen: View {
    let slug: String
    var title: String?

    var body: some View {
        let page = LocalContent.page(slug)
        ScrollView {
            if let page {
                MarkdownView(page.body)
                    .padding()
            } else {
                ContentUnavailableView("Сторінку не знайдено", systemImage: "doc.questionmark")
            }
        }
        .navigationTitle(title ?? page?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Пункт меню, що веде на сторінку. Порожні сторінки (`status: empty`) не показуємо.
struct PageLink: View {
    let title: String
    let slug: String
    var systemImage: String?

    var body: some View {
        if LocalContent.page(slug)?.isEmpty == false {
            NavigationLink {
                PageScreen(slug: slug, title: title)
            } label: {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
        }
    }
}
