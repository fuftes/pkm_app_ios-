import Foundation

/// Один уривок із `verses.json` (Новий Завіт, переклад Івана Хоменка).
struct Verse: Codable, Identifiable, Hashable {
    let id: Int
    let ref: String
    let text: String
}

/// Спільне для застосунку й віджетів: список віршів, особистий випадковий порядок, тестовий вибір.
enum VerseStore {
    /// App Group, через яку застосунок і віджети бачать ті самі налаштування.
    /// Без App Group (наприклад, без підпису командою) кожен бере власні налаштування — віджети все одно працюють.
    static let appGroup = "group.ua.if.pkm.app"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static let all: [Verse] = {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("verses.json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(VerseFile.self, from: data) else {
            return [Verse(id: 0, ref: "Ів 3,16",
                          text: "Бог бо так полюбив світ, що дав Сина свого єдинородного, щоб кожен, хто вірує в нього, не загинув, але жив життям вічним.")]
        }
        return file.verses
    }()

    static func verse(id: Int) -> Verse? {
        all.first { $0.id == id }
    }

    // MARK: Особистий порядок

    private enum Key {
        static let seed = "verses.seed"
        static let start = "verses.startDay"
        static let override = "verses.overrideID"
        static let lockSize = "verses.lockWidgetSize"
        static let gap = "verses.widgetGap"
    }

    /// Випадкове число, створене один раз на цьому телефоні. З нього виходить особистий порядок віршів.
    static var seed: UInt64 {
        if let stored = defaults.string(forKey: Key.seed), let value = UInt64(stored) {
            return value
        }
        let value = UInt64.random(in: 1...UInt64.max)
        defaults.set(String(value), forKey: Key.seed)
        return value
    }

    /// День, від якого рахуємо «вірш дня».
    static var startDay: Date {
        if let date = defaults.object(forKey: Key.start) as? Date {
            return date
        }
        let today = Calendar.current.startOfDay(for: .now)
        defaults.set(today, forKey: Key.start)
        return today
    }

    /// Новий особистий порядок (для тестів).
    static func resetPersonalOrder() {
        defaults.removeObject(forKey: Key.seed)
        defaults.removeObject(forKey: Key.start)
        cacheLock.lock()
        cachedOrders.removeAll()
        cacheLock.unlock()
    }

    private static var cachedOrders: [String: [Int]] = [:]
    private static let cacheLock = NSLock()

    /// Перемішаний список індексів для одного «кола» з 365 днів. Після кожного кола — нове перемішування.
    static func order(cycle: Int) -> [Int] {
        let key = "\(seed)-\(cycle)"
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cachedOrders[key] { return cached }
        var generator = SplitMix64(seed: seed &+ UInt64(cycle) &* 0x9E37_79B9_7F4A_7C15)
        // Власне перемішування (Фішер — Єйтс), щоб порядок не змінився з оновленням iOS.
        var order = Array(all.indices)
        if order.count > 1 {
            for i in stride(from: order.count - 1, to: 0, by: -1) {
                let j = Int(generator.next() % UInt64(i + 1))
                order.swapAt(i, j)
            }
        }
        cachedOrders[key] = order
        return order
    }

    /// Номер дня від початку (0, 1, 2 …).
    static func dayNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDay, to: calendar.startOfDay(for: date)).day ?? 0
        return max(0, days)
    }

    /// Вірш на день із особистого порядку. `accepts` дозволяє пропустити ті, що не вміщаються у віджет.
    static func verse(for date: Date, accepts: (Verse) -> Bool = { _ in true }) -> Verse {
        let count = all.count
        let day = dayNumber(for: date)
        for step in 0..<count {
            let position = day + step
            let index = order(cycle: position / count)[position % count]
            if accepts(all[index]) { return all[index] }
        }
        return all[order(cycle: day / count)[day % count]]
    }

    // MARK: Тестовий вибір (тимчасово)

    /// Вірш, вибраний вручну на тестовому екрані. Поки він є, усі віджети показують саме його.
    static var overrideID: Int? {
        get { defaults.object(forKey: Key.override) as? Int }
        set {
            if let newValue { defaults.set(newValue, forKey: Key.override) }
            else { defaults.removeObject(forKey: Key.override) }
        }
    }

    // MARK: Проміжок між віджетами

    /// Відстань між лівим і правим віджетом на заблокованому екрані, у пунктах.
    /// Стільки ж і між усіма словами, щоб межа між віджетами виглядала як звичайний проміжок.
    /// Точне значення iOS не повідомляє, тому його підбирають на тестовому екрані.
    static let defaultWidgetGap: CGFloat = 12

    static var widgetGap: CGFloat {
        get {
            let value = defaults.double(forKey: Key.gap)
            return value > 0 ? CGFloat(value) : defaultWidgetGap
        }
        set { defaults.set(Double(newValue), forKey: Key.gap) }
    }

    // MARK: Розмір віджета на заблокованому екрані

    /// Віджет записує свій розмір, щоб тестовий екран міг показати, чи вміщається вірш.
    static var lockWidgetSize: CGSize? {
        get {
            guard let pair = defaults.array(forKey: Key.lockSize) as? [Double], pair.count == 2 else { return nil }
            return CGSize(width: pair[0], height: pair[1])
        }
        set {
            if let newValue { defaults.set([Double(newValue.width), Double(newValue.height)], forKey: Key.lockSize) }
            else { defaults.removeObject(forKey: Key.lockSize) }
        }
    }
}

private struct VerseFile: Decodable {
    let verses: [Verse]
}

/// Простий генератор із заданим початковим числом: той самий seed — той самий порядок.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
