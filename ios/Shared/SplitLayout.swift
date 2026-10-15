import UIKit

/// Розкладає вірш на дві половини для пари віджетів на заблокованому екрані («Лівий» і «Правий»).
///
/// Кожен рядок ділиться на ліву й праву частину лише між словами. Читати треба рядок за рядком:
/// ліва частина першого рядка → права частина першого рядка → ліва частина другого …
/// Обидва віджети рахують це однаково (той самий текст, шрифт і ширина), тому половини збігаються.
struct SplitLayout: Equatable {
    struct Token: Equatable {
        let text: String
        let isReference: Bool
    }

    struct Row: Equatable {
        var left: [Token] = []
        var right: [Token] = []
    }

    let fontSize: CGFloat
    let rows: [Row]
    /// Текст не вмістився навіть найменшим шрифтом і обрізаний.
    let truncated: Bool

    var font: UIFont { Self.font(size: fontSize) }
    var lineHeight: CGFloat { font.lineHeight }
    var spaceWidth: CGFloat { Self.width(" ", font: font) }

    /// Від найбільшого до найменшого. Береться перший, з яким увесь вірш вміщається.
    static let fontSizes: [CGFloat] = [17, 16, 15, 14, 13, 12]

    /// Запас по краю, щоб слово ніколи не обрізалося через різницю округлення.
    static let safetyMargin: CGFloat = 4

    static func font(size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .medium)
    }

    static func width(_ string: String, font: UIFont) -> CGFloat {
        ceil((string as NSString).size(withAttributes: [.font: font]).width)
    }

    /// `columnWidth` і `height` — розмір одного віджета.
    static func make(verse: Verse, columnWidth: CGFloat, height: CGFloat) -> SplitLayout {
        let tokens = tokenize(verse)
        for size in fontSizes {
            let uiFont = Self.font(size: size)
            let maxRows = max(1, Int(floor(height / uiFont.lineHeight)))
            let rows = fill(tokens, font: uiFont, columnWidth: columnWidth)
            if rows.count <= maxRows {
                return SplitLayout(fontSize: size, rows: rows, truncated: false)
            }
        }
        // Не вмістилося: найменший шрифт, зайві рядки відкидаємо, в кінці — «…».
        let size = fontSizes.last ?? 12
        let uiFont = Self.font(size: size)
        let maxRows = max(1, Int(floor(height / uiFont.lineHeight)))
        var rows = Array(fill(tokens, font: uiFont, columnWidth: columnWidth).prefix(maxRows))
        if var last = rows.popLast() {
            if last.right.isEmpty {
                last.left.append(Token(text: "…", isReference: false))
            } else {
                last.right.append(Token(text: "…", isReference: false))
            }
            rows.append(last)
        }
        return SplitLayout(fontSize: size, rows: rows, truncated: true)
    }

    /// Чи вміщається вірш у пару віджетів такого розміру без обрізання.
    static func fits(_ verse: Verse, columnWidth: CGFloat, height: CGFloat) -> Bool {
        !make(verse: verse, columnWidth: columnWidth, height: height).truncated
    }

    private static func tokenize(_ verse: Verse) -> [Token] {
        var tokens = verse.text
            .split(whereSeparator: { $0 == " " || $0 == "\n" })
            .map { Token(text: String($0), isReference: false) }
        // Посилання — одним шматком, щоб «Ів 3,16» не розірвалося між віджетами.
        let reference = "— " + verse.ref
        tokens.append(Token(text: reference.replacingOccurrences(of: " ", with: "\u{00A0}"), isReference: true))
        return tokens
    }

    private static func fill(_ tokens: [Token], font: UIFont, columnWidth: CGFloat) -> [Row] {
        let available = columnWidth - safetyMargin
        let space = width(" ", font: font)
        var rows: [Row] = []
        var index = 0
        while index < tokens.count {
            var row = Row()
            for side in 0..<2 {
                var used: CGFloat = 0
                var part: [Token] = []
                while index < tokens.count {
                    let tokenWidth = width(tokens[index].text, font: font)
                    let needed = part.isEmpty ? tokenWidth : used + space + tokenWidth
                    if needed <= available || part.isEmpty && tokenWidth > available {
                        // Задовге слово ставимо саме по собі — його стисне minimumScaleFactor.
                        part.append(tokens[index])
                        used = needed
                        index += 1
                        if tokenWidth > available { break }
                    } else {
                        break
                    }
                }
                if side == 0 { row.left = part } else { row.right = part }
            }
            rows.append(row)
        }
        return rows
    }
}
