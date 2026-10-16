import SwiftUI
import WidgetKit

@main
struct PKMWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseLockWidget()
        VerseHomeWidget()
    }
}

// MARK: Заблокований екран: один прямокутний віджет

struct VerseLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseLock", provider: VerseProvider(lockScreen: true)) { entry in
            LockTextView(content: entry.content, maxFontSize: entry.fontSize, autoFont: entry.autoFont)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Слово на день")
        .description("Короткий уривок зі Святого Письма на заблокованому екрані.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: Домашній екран: середній (широкий) віджет

struct VerseHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseHome", provider: VerseProvider(lockScreen: false)) { entry in
            VerseHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Слово на день")
        .description("Уривок зі Святого Письма. Щодня новий, у вашому особистому порядку.")
        .supportedFamilies([.systemMedium])
    }
}

struct VerseHomeWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.content.body)
                .font(.system(size: 17, weight: .medium))
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                Text("Слово на день")
                Spacer()
                Text(entry.content.reference?.replacingOccurrences(of: "— ", with: "") ?? "")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

#Preview(as: .accessoryRectangular) {
    VerseLockWidget()
} timeline: {
    VerseEntry(date: .now, content: .verse(VerseStore.all[0], withReference: true), fontSize: 17, autoFont: true)
    VerseEntry(date: .now, content: .filler(length: 90, withReference: true), fontSize: 17, autoFont: true)
}

#Preview(as: .systemMedium) {
    VerseHomeWidget()
} timeline: {
    VerseEntry(date: .now, content: .verse(VerseStore.all[0], withReference: true), fontSize: 17, autoFont: true)
}
