import SwiftUI

/// Картинка з мережі з плейсхолдером.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
            switch phase {
            case let .success(image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(systemImage: "photo")
            default:
                placeholder(systemImage: nil)
            }
        }
    }

    private func placeholder(systemImage: String?) -> some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(.secondary)
                }
            }
            .aspectRatio(contentMode == .fit ? CGFloat(16) / 9 : nil, contentMode: .fit)
    }
}
