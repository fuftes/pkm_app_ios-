import Foundation

/// Усі «жорсткі» адреси, контакти й налаштування застосунку в одному місці.
enum AppConfig {
    static let siteURL = URL(string: "https://pkm.if.ua")!

    /// Публічний репозиторій зі змістом (PDF-буклети, фото) — звідси вантажимо великі файли,
    /// щоб не роздувати застосунок. Тексти сторінок і проповідей вшиті в застосунок.
    static let contentBaseURL = URL(string: "https://raw.githubusercontent.com/fuftes/pkm_app_ios-/main/")!

    static let parishName = "Парафія Святих Кирила і Методія"
    static let parishSubtitle = "УГКЦ · Згромадження Воплоченого Слова"
    static let address = "вул. Вербова, 32, с. Крихівці, Івано-Франківськ"
    static var mapsURL: URL {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [URLQueryItem(name: "q", value: "Храм Святих Кирила і Методія, вул. Вербова 32, Крихівці, Івано-Франківськ")]
        return components.url!
    }

    static let priestEmail = "josafatboyko@ive.org"
    static let phone = "+380989488025"
    static let phoneDisplay = "+38 (098) 948-80-25"

    static let youtubeChannel = URL(string: "https://www.youtube.com/channel/UCz0j4soYp3KcKE-AJH20sTQ")!
    static let facebook = URL(string: "https://www.facebook.com/JosafatBoyko1979")!

    static var phoneURL: URL { URL(string: "tel:\(phone)")! }
    static var emailURL: URL { URL(string: "mailto:\(priestEmail)")! }

    /// Повна адреса файлу з репозиторію змісту (наприклад, `booklets/x.pdf`).
    static func contentURL(_ relativePath: String) -> URL {
        contentBaseURL.appendingPathComponent(relativePath)
    }
}

/// Рубрики WordPress на pkm.if.ua (id з /wp-json/wp/v2/categories).
enum WPCategory {
    static let uncategorized = 1
    static let parishNews = 2
    static let ugccNews = 3
    static let sermons = 4
    static let articles = 5
    static let visnyk = 9
    static let answers = 12
    static let spiritual = 15
}

/// Реквізити для пожертв — зі сторінки «Жертводавцям». Перевіряти при кожній зміні на сайті.
enum DonationInfo {
    static let project = "Місія «Центр соціального служіння»"
    static let recipient = "Монастир ЗВС в Івано-Франківську Івано-Франківської Архієпархії УГКЦ"
    static let edrpou = "25597817"
    static let iban = "UA063363100000026003300031769"
    static let bank = "АТ «Ідея Банк», м. Львів"
    static let card = "5363 5420 9530 4664"
    static let cardBank = "ПриватБанк"
    static let cardHolder = "Бойко Василь Петрович"
    static let cardPurpose = "Добровільна пожертва на ЦСС"
}
