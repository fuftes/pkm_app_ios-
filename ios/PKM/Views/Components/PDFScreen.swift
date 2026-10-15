import PDFKit
import SwiftUI

/// Перегляд PDF з мережі. Файл кешується, тож відкривається повторно й без інтернету.
struct PDFScreen: View {
    let title: String
    let url: URL

    @State private var fileURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let fileURL {
                PDFKitView(fileURL: fileURL)
                    .ignoresSafeArea(edges: .bottom)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Не вдалося завантажити", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Спробувати ще") { Task { await load() } }
                }
            } else {
                ProgressView("Завантаження…")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let fileURL {
                ShareLink(item: fileURL)
            }
        }
        .task { await load() }
    }

    private func load() async {
        errorMessage = nil
        let cached = PDFScreen.cacheURL(for: url)
        if FileManager.default.fileExists(atPath: cached.path) {
            fileURL = cached
            return
        }
        do {
            let (temporary, response) = try await URLSession.shared.download(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            try? FileManager.default.removeItem(at: cached)
            try FileManager.default.moveItem(at: temporary, to: cached)
            fileURL = cached
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func cacheURL(for url: URL) -> URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDF", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = url.pathComponents.suffix(2).joined(separator: "-")
        return directory.appendingPathComponent(name)
    }
}

private struct PDFKitView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .secondarySystemBackground
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != fileURL {
            view.document = PDFDocument(url: fileURL)
        }
    }
}
