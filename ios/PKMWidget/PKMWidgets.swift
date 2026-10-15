import SwiftUI
import WidgetKit

@main
struct PKMWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseLockLeftWidget()
        VerseLockRightWidget()
        VerseHomeWidget()
    }
}

// MARK: Заблокований екран: пара «ліва + права половина»

struct VerseLockLeftWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseLockLeft", provider: VerseProvider(lockScreenPair: true)) { entry in
            LockHalfWidgetView(entry: entry, side: .left)
        }
        .configurationDisplayName("Вірш · ліва половина")
        .description("Поставте ліворуч, а праву половину — поруч праворуч. Текст продовжиться в ній.")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct VerseLockRightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseLockRight", provider: VerseProvider(lockScreenPair: true)) { entry in
            LockHalfWidgetView(entry: entry, side: .right)
        }
        .configurationDisplayName("Вірш · права половина")
        .description("Поставте праворуч від лівої половини.")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct LockHalfWidgetView: View {
    let entry: VerseEntry
    let side: SplitSide

    var body: some View {
        SplitHalfView(verse: entry.verse, side: side)
            .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: Домашній екран: середній (широкий) віджет

struct VerseHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseHome", provider: VerseProvider(lockScreenPair: false)) { entry in
            VerseHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Слово на день")
        .description("Уривок із Нового Завіту. Щодня новий, у вашому особистому порядку.")
        .supportedFamilies([.systemMedium])
    }
}

struct VerseHomeWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.verse.text)
                .font(.system(size: 17, weight: .medium))
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                Text("Слово на день")
                Spacer()
                Text(entry.verse.ref)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

#Preview(as: .accessoryRectangular) {
    VerseLockLeftWidget()
} timeline: {
    VerseEntry(date: .now, verse: VerseStore.all[0])
}

#Preview(as: .systemMedium) {
    VerseHomeWidget()
} timeline: {
    VerseEntry(date: .now, verse: VerseStore.all[0])
}
