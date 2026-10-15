import SwiftUI

/// Вкладка «Інше»: про парафію, священники, духовні вправи, контакти та решта сторінок сайту.
struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ParishHeader()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section("Про нашу парафію") {
                    DisclosureGroup {
                        PageLink(title: "Парафія сьогодні", slug: "parafiya-sogodni")
                        PageLink(title: "Історія парафії", slug: "istoriya-parafiyi")
                        PageLink(title: "Святі Покровителі", slug: "svyati-pokrovyteli")
                        NavigationLink("Галерея храму") { GalleryView() }
                    } label: {
                        Label("Парафія", systemImage: "building.columns")
                    }

                    DisclosureGroup {
                        PageLink(title: "Парох", slug: "paroh")
                        PageLink(title: "Священники-сотрудники", slug: "sotrudnyky")
                        PageLink(title: "Сестри-монахині", slug: "sestry-monahyni")
                        PageLink(title: "Семінаристи", slug: "seminarysty")
                        PageLink(title: "Паламар", slug: "palamar")
                        PageLink(title: "Дяк", slug: "dyak")
                        NavigationLink("Запитай священника") { MessageFormView(kind: .askPriest) }
                    } label: {
                        Label("Священники", systemImage: "person.3")
                    }

                    DisclosureGroup {
                        PageLink(title: "Що таке Духовні вправи?", slug: "shcho-take-dukhovni-vpravy")
                        PageLink(title: "Про автора — св. Ігнатія з Лойоли", slug: "pro-avtora-sv-ihnatii-z-loioly")
                        PageLink(title: "Дати проведення", slug: "daty-provedennia")
                        PageLink(title: "Запис", slug: "zapys")
                    } label: {
                        Label("Духовні вправи", systemImage: "leaf")
                    }

                    DisclosureGroup {
                        PageLink(title: "Катехизація", slug: "katehyzatsiya")
                        PageLink(title: "Ораторій", slug: "oratorij")
                        PageLink(title: "Дитячий майданчик", slug: "dytyachyj-majdanchyk")
                    } label: {
                        Label("Для дітей", systemImage: "figure.2.and.child.holdinghands")
                    }

                    DisclosureGroup {
                        PageLink(title: "Згромадження Отців ЗВС", slug: "zgromadzhennya-ottsiv-zvs")
                        PageLink(title: "Згромадження Сестер СГДММ", slug: "zgromadzhennya-sester-sgdmm")
                        PageLink(title: "ІІІ Чин ЗВС", slug: "iii-chyn-zvs")
                        PageLink(title: "Дім Милосердя", slug: "dim-myloserdya")
                        PageLink(title: "Історія Згромадження у світі", slug: "istoriya-zasnuvannya")
                        PageLink(title: "Історія Згромадження в Україні", slug: "istoriya-v-ukrayini")
                        PageLink(title: "Харизма", slug: "haryzma")
                        PageLink(title: "Власні апостоляти", slug: "vlasni-apostoliaty")
                    } label: {
                        Label("Чернеча родина", systemImage: "house.lodge")
                    }
                }

                Section("Контакти") {
                    Link(destination: AppConfig.phoneURL) {
                        Label(AppConfig.phoneDisplay, systemImage: "phone")
                    }
                    Link(destination: AppConfig.emailURL) {
                        Label(AppConfig.priestEmail, systemImage: "envelope")
                    }
                    Link(destination: AppConfig.mapsURL) {
                        Label(AppConfig.address, systemImage: "map")
                    }
                    DisclosureGroup {
                        PageLink(title: "Івано-Франківськ", slug: "ivano-frankivsk")
                        PageLink(title: "Вінниця", slug: "vinnytsya")
                        PageLink(title: "Дубове", slug: "dubove")
                        PageLink(title: "Скадовськ", slug: "skadovsk")
                    } label: {
                        Label("Спільноти Згромадження", systemImage: "mappin.and.ellipse")
                    }
                }

                Section("Радимо вам") {
                    DisclosureGroup {
                        ForEach(UsefulLink.all) { link in
                            Link(link.title, destination: link.url)
                        }
                    } label: {
                        Label("Корисні сайти", systemImage: "link")
                    }
                }

                Section {
                    Link(destination: AppConfig.siteURL) {
                        Label("Сайт pkm.if.ua", systemImage: "safari")
                    }
                } footer: {
                    Text("Версія \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Інше")
        }
    }
}

/// Шапка: надпис «Кирила і Методія», назва, швидкі дії.
private struct ParishHeader: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("BrandTitle")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .accessibilityLabel(AppConfig.parishName)
            VStack(spacing: 2) {
                Text(AppConfig.parishName)
                    .font(.headline)
                Text(AppConfig.parishSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                QuickAction(title: "Подзвонити", systemImage: "phone.fill", url: AppConfig.phoneURL)
                QuickAction(title: "Маршрут", systemImage: "map.fill", url: AppConfig.mapsURL)
                QuickAction(title: "Написати", systemImage: "envelope.fill", url: AppConfig.emailURL)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

private struct QuickAction: View {
    let title: String
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct UsefulLink: Identifiable {
    let title: String
    let url: URL
    var id: String { url.absoluteString }

    /// Блок «Радимо Вам» з головної сторінки сайту.
    static let all: [UsefulLink] = make([
        ("Офіційний сайт Ватикану", "https://www.vatican.va/content/vatican/uk.html"),
        ("Новини з Ватикану", "https://www.vaticannews.va/uk.html"),
        ("Українська Греко-Католицька Церква", "https://ugcc.ua/"),
        ("Івано-Франківська Архієпархія", "https://ugccif.org.ua/"),
        ("Згромадження Воплоченого Слова у світі", "https://ive.org/"),
        ("Згромадження Воплоченого Слова в Україні", "http://iveukraine.com.ua/"),
        ("Апостольська Нунціатура в Україні", "https://nunciaturekyiv.org/"),
        ("Живе Телебачення", "https://zhyve.tv/"),
        ("Католицький часопис «CREDO»", "https://credo.pro/"),
        ("Радіо «Марія»", "http://radiomaria.org.ua/"),
        ("Релігійно-інформаційна служба України", "https://risu.ua/"),
    ])

    private static func make(_ pairs: [(title: String, address: String)]) -> [UsefulLink] {
        pairs.compactMap { pair in
            URL(string: pair.address).map { UsefulLink(title: pair.title, url: $0) }
        }
    }
}
