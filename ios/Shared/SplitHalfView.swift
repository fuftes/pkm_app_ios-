import SwiftUI

enum SplitSide {
    case left, right
}

/// Одна половина вірша (ліва або права). Використовують віджети на заблокованому екрані
/// і тестовий екран у застосунку (попередній перегляд пари).
///
/// Ліва половина притиснута до правого краю, права — до лівого. Між словами всюди однаковий
/// проміжок `layout.gap`, такий самий, як між віджетами, тож рядок читається суцільно.
struct SplitHalfView: View {
    let verse: Verse
    let side: SplitSide
    var gap: CGFloat = VerseStore.widgetGap

    var body: some View {
        GeometryReader { geometry in
            let layout = SplitLayout.make(verse: verse,
                                          columnWidth: geometry.size.width,
                                          height: geometry.size.height,
                                          gap: gap)
            VStack(spacing: 0) {
                ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                    SplitRowView(tokens: side == .left ? row.left : row.right, layout: layout)
                        .frame(width: geometry.size.width,
                               height: layout.lineHeight,
                               alignment: side == .left ? .trailing : .leading)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

private struct SplitRowView: View {
    let tokens: [SplitLayout.Token]
    let layout: SplitLayout

    var body: some View {
        HStack(spacing: layout.gap) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Text(token.text)
                    .font(Font(layout.font as CTFont))
                    .foregroundStyle(token.isReference ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}
