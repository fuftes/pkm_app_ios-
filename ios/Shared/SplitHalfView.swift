import SwiftUI

enum SplitSide {
    case left, right
}

/// Одна половина вірша (ліва або права). Використовують віджети на заблокованому екрані
/// і тестовий екран у застосунку (попередній перегляд пари).
struct SplitHalfView: View {
    let verse: Verse
    let side: SplitSide

    var body: some View {
        GeometryReader { geometry in
            let layout = SplitLayout.make(verse: verse,
                                          columnWidth: geometry.size.width,
                                          height: geometry.size.height)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                    SplitRowView(tokens: side == .left ? row.left : row.right,
                                 // Ліву частину розтягуємо до правого краю, щоб текст «перетікав» у правий віджет.
                                 justify: side == .left && !row.right.isEmpty,
                                 layout: layout)
                        .frame(width: geometry.size.width, height: layout.lineHeight, alignment: .leading)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

private struct SplitRowView: View {
    let tokens: [SplitLayout.Token]
    let justify: Bool
    let layout: SplitLayout

    var body: some View {
        if justify && tokens.count > 1 {
            HStack(spacing: 0) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                    if index > 0 {
                        Spacer(minLength: layout.spaceWidth)
                    }
                    styled(token)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        } else {
            tokens.enumerated().reduce(Text("")) { result, item in
                (item.offset > 0 ? result + Text(" ") : result) + styled(item.element)
            }
            .font(Font(layout.font as CTFont))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private func styled(_ token: SplitLayout.Token) -> Text {
        Text(token.text)
            .font(Font(layout.font as CTFont))
            .foregroundStyle(token.isReference ? Color.secondary : Color.primary)
    }
}
