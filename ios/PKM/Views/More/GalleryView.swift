import SwiftUI

/// Галерея храму: «Зовні» і «Всередині». Фото вантажаться з репозиторію змісту.
struct GalleryView: View {
    private let gallery = LocalContent.gallery
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 4)]

    @State private var opened: OpenedPhoto?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                section("Зовні", gallery.outside)
                section("Всередині", gallery.inside)
            }
            .padding(.vertical)
        }
        .navigationTitle("Галерея")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $opened) { photo in
            PhotoPager(photos: photo.photos, selection: photo.photo.id)
        }
    }

    private func section(_ title: String, _ photos: [GalleryPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(photos) { photo in
                    Button {
                        opened = OpenedPhoto(photo: photo, photos: photos)
                    } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { RemoteImage(url: photo.url) }
                            .clipped()
                    }
                    .accessibilityLabel(photo.caption)
                }
            }
        }
    }
}

private struct OpenedPhoto: Identifiable {
    let photo: GalleryPhoto
    let photos: [GalleryPhoto]
    var id: String { photo.id }
}

private struct PhotoPager: View {
    let photos: [GalleryPhoto]
    @State var selection: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView(selection: $selection) {
            ForEach(photos) { photo in
                VStack {
                    Spacer()
                    RemoteImage(url: photo.url, contentMode: .fit)
                    Spacer()
                    Text(photo.caption)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.bottom, 48)
                }
                .tag(photo.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(.black)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.25))
            }
            .padding()
            .accessibilityLabel("Закрити")
        }
    }
}
