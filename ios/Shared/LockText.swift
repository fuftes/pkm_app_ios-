import SwiftUI
import UIKit

/// Текст для віджета на заблокованому екрані: сам вірш (або тестові символи) і посилання.
struct LockContent: Equatable {
    let body: String
    let reference: String?

    /// Одним рядком, як його бачить вимірювання: «текст — Ів 3,16».
    var combined: String {
        guard let reference else { return body }
        return body + " " + reference
    }

    static func verse(_ verse: Verse, withReference: Bool) -> LockContent {
        LockContent(body: verse.text, reference: withReference ? "— " + verse.ref : nil)
    }

    /// Найдовше посилання серед усіх віршів (з тире): «— 1 Пт 1,24-25», 14 знаків.
    static let longestReference: String = {
        let longest = VerseStore.all.map(\.ref).max { $0.count < $1.count } ?? "1 Пт 1,24-25"
        return "— " + longest
    }()

    /// Випадкові «слова» з українських літер рівно на `length` знаків (з пробілами).
    /// Завжди однакові для тієї самої довжини, щоб порівнювати спроби між собою.
    static func filler(length: Int, withReference: Bool) -> LockContent {
        let letters = Array("абвгдежзиіїйклмнопрстуфхцчшщьюяєґ")
        var generator = SplitMix64(seed: 2026)
        var text = ""
        while text.count < length {
            if !text.isEmpty { text.append(" ") }
            let wordLength = 2 + Int(generator.next() % 8) // від 2 до 9 літер
            for _ in 0..<wordLength {
                text.append(letters[Int(generator.next() % UInt64(letters.count))])
            }
        }
        var body = String(text.prefix(length))
        if body.hasSuffix(" ") { body = String(body.dropLast()) + "а" }
        return LockContent(body: body, reference: withReference ? longestReference : nil)
    }
}

/// Розрахунок: чи вміщається текст у віджет заданого розміру без «…».
enum LockFit {
    static func font(size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .medium)
    }

    static func fits(_ content: LockContent, in size: CGSize, fontSize: CGFloat) -> Bool {
        guard size.width > 0, size.height > 0 else { return true }
        let rect = (content.combined as NSString).boundingRect(
            with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font(size: fontSize)],
            context: nil)
        return ceil(rect.height) <= size.height
    }

    static func fits(_ verse: Verse, in size: CGSize,
                     fontSize: CGFloat = VerseStore.lockFontSize,
                     withReference: Bool = VerseStore.showReference) -> Bool {
        fits(.verse(verse, withReference: withReference), in: size, fontSize: fontSize)
    }

    /// Найбільша кількість знаків тексту, що ще вміщається (за розрахунком, не на око).
    static func maxLength(in size: CGSize, fontSize: CGFloat, withReference: Bool) -> Int {
        var low = 0, high = 400
        while low < high {
            let mid = (low + high + 1) / 2
            if fits(.filler(length: mid, withReference: withReference), in: size, fontSize: fontSize) {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }
}

/// Як текст виглядає на віджеті. Спільне для віджета і попереднього перегляду в застосунку.
struct LockTextView: View {
    let content: LockContent
    let fontSize: CGFloat

    var body: some View {
        text
            .font(.system(size: fontSize, weight: .medium))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var text: Text {
        guard let reference = content.reference else { return Text(content.body) }
        return Text(content.body) + Text(" " + reference).foregroundStyle(.secondary)
    }
}
