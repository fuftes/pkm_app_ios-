import WidgetKit

struct VerseEntry: TimelineEntry {
    let date: Date
    let content: LockContent
    let fontSize: CGFloat
}

/// Дає віджетам вірш дня. Новий вірш — щоночі о 00:00.
struct VerseProvider: TimelineProvider {
    /// Віджет на заблокованому екрані: лише вірші, що вміщаються без «…», і тестовий режим вимірювання.
    let lockScreen: Bool

    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now,
                   content: .verse(VerseStore.verse(id: 1) ?? VerseStore.all[0], withReference: true),
                   fontSize: VerseStore.lockFontSize)
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(entry(for: .now, size: context.displaySize))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let size = context.displaySize
        if lockScreen, size.width > 0 {
            VerseStore.lockWidgetSize = size
        }

        // Тестові режими: вимірювання або вручну вибраний вірш — без розкладу на дні.
        if (lockScreen && VerseStore.measureEnabled) || VerseStore.overrideID != nil {
            completion(Timeline(entries: [entry(for: .now, size: size)], policy: .never))
            return
        }

        let calendar = Calendar.current
        var entries = [entry(for: .now, size: size)]
        let today = calendar.startOfDay(for: .now)
        for offset in 1...7 {
            guard let midnight = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            entries.append(entry(for: midnight, size: size))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date, size: CGSize) -> VerseEntry {
        let fontSize = VerseStore.lockFontSize
        let withReference = VerseStore.showReference

        if lockScreen && VerseStore.measureEnabled {
            return VerseEntry(date: date,
                              content: .filler(length: VerseStore.measureLength, withReference: withReference),
                              fontSize: fontSize)
        }

        let verse: Verse
        if let id = VerseStore.overrideID, let chosen = VerseStore.verse(id: id) {
            verse = chosen
        } else if lockScreen, size.width > 0, size.height > 0 {
            verse = VerseStore.verse(for: date) { LockFit.fits($0, in: size, fontSize: fontSize, withReference: withReference) }
        } else {
            verse = VerseStore.verse(for: date)
        }
        return VerseEntry(date: date,
                          content: .verse(verse, withReference: lockScreen ? withReference : true),
                          fontSize: fontSize)
    }
}
