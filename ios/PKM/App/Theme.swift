import SwiftUI

/// Кольори бренду парафії (див. `brand/` у репозиторії змісту).
enum Brand {
    static let crimson = Color(red: 0xB0 / 255, green: 0x28 / 255, blue: 0x3A / 255)
    static let gold = Color(red: 0xB8 / 255, green: 0x90 / 255, blue: 0x2E / 255)
    static let green = Color(red: 0x4D / 255, green: 0x96 / 255, blue: 0x42 / 255)
}

extension Date {
    /// «7 серпня 2026»
    var parishDay: String {
        formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "uk_UA")))
    }
}
