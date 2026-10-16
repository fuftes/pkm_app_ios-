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

    static func verse(_ verse: Verse,
                      withReference: Bool,
                      withDash: Bool = VerseStore.showDash) -> LockContent {
        LockContent(body: verse.text,
                    reference: withReference ? (withDash ? "— " : "") + verse.ref : nil)
    }

    /// Найдовше посилання серед усіх віршів, наприклад «— 1 Пт 1,24-25».
    static func longestReference(withDash: Bool) -> String {
        let longest = VerseStore.all.map(\.ref).max { $0.count < $1.count } ?? "1 Пт 1,24-25"
        return (withDash ? "— " : "") + longest
    }

    /// Випадкові «слова» з українських літер рівно на `length` знаків (з пробілами).
    /// Завжди однакові для тієї самої довжини, щоб порівнювати спроби між собою.
    static func filler(length: Int,
                       withReference: Bool,
                       withDash: Bool = VerseStore.showDash) -> LockContent {
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
        return LockContent(body: body,
                           reference: withReference ? longestReference(withDash: withDash) : nil)
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

    /// Найбільший розмір шрифту (від `maxSize` до `minSize`, крок 0,5 пт), з яким текст вміщається.
    /// Якщо автопідбір вимкнено — завжди `maxSize`. Якщо не вміщається й найменшим — `nil`.
    static func bestFontSize(_ content: LockContent, in size: CGSize,
                             maxSize: CGFloat, minSize: CGFloat, auto: Bool) -> CGFloat? {
        guard auto else { return fits(content, in: size, fontSize: maxSize) ? maxSize : nil }
        var current = maxSize
        while current >= minSize {
            if fits(content, in: size, fontSize: current) { return current }
            current -= 0.5
        }
        return nil
    }

    /// Чи вміщається вірш у віджет за поточними налаштуваннями (з автопідбором шрифту чи без).
    static func fits(_ verse: Verse, in size: CGSize,
                     maxSize: CGFloat = VerseStore.lockFontSize,
                     auto: Bool = VerseStore.autoFont,
                     withReference: Bool = VerseStore.showReference,
                     withDash: Bool = VerseStore.showDash) -> Bool {
        bestFontSize(.verse(verse, withReference: withReference, withDash: withDash), in: size,
                     maxSize: maxSize, minSize: VerseStore.minLockFontSize, auto: auto) != nil
    }

    /// Найбільша кількість знаків тексту, що ще вміщається (за розрахунком, не на око).
    static func maxLength(in size: CGSize, maxSize: CGFloat, auto: Bool,
                          withReference: Bool, withDash: Bool) -> Int {
        var low = 0, high = 600
        while low < high {
            let mid = (low + high + 1) / 2
            let content = LockContent.filler(length: mid, withReference: withReference, withDash: withDash)
            if bestFontSize(content, in: size, maxSize: maxSize,
                            minSize: VerseStore.minLockFontSize, auto: auto) != nil {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }
}

/// Як текст виглядає на віджеті. Спільне для віджета і попереднього перегляду в застосунку.
/// Розмір шрифту підбирається сам: від `maxFontSize` вниз до найменшого, з яким усе вміщається.
struct LockTextView: View {
    let content: LockContent
    let maxFontSize: CGFloat
    let autoFont: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = LockFit.bestFontSize(content, in: geometry.size,
                                            maxSize: maxFontSize,
                                            minSize: VerseStore.minLockFontSize,
                                            auto: autoFont)
                ?? (autoFont ? VerseStore.minLockFontSize : maxFontSize)
            text
                .font(.system(size: size, weight: .medium))
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private var text: Text {
        guard let reference = content.reference else { return Text(content.body) }
        return Text(content.body) + Text(" " + reference).foregroundStyle(.secondary)
    }
}
