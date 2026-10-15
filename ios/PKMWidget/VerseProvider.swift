import WidgetKit

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: Verse
}

/// Дає віджетам вірш дня. Новий вірш — щоночі о 00:00.
/// Обидві половини на заблокованому екрані рахують однаково, тому завжди показують той самий вірш.
struct VerseProvider: TimelineProvider {
    /// Для віджетів на заблокованому екрані беремо лише вірші, що вміщаються в пару без обрізання.
    let lockScreenPair: Bool

    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: VerseStore.verse(id: 1) ?? VerseStore.all[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, verse: verse(for: .now, size: context.displaySize)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let size = context.displaySize
        if lockScreenPair, size.width > 0 {
            VerseStore.lockWidgetSize = size
        }

        // Тестовий режим: вірш вибрано вручну в застосунку.
        if let id = VerseStore.overrideID, let chosen = VerseStore.verse(id: id) {
            completion(Timeline(entries: [VerseEntry(date: .now, verse: chosen)], policy: .never))
            return
        }

        let calendar = Calendar.current
        var entries = [VerseEntry(date: .now, verse: verse(for: .now, size: size))]
        let today = calendar.startOfDay(for: .now)
        for offset in 1...7 {
            guard let midnight = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            entries.append(VerseEntry(date: midnight, verse: verse(for: midnight, size: size)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func verse(for date: Date, size: CGSize) -> Verse {
        if let id = VerseStore.overrideID, let chosen = VerseStore.verse(id: id) {
            return chosen
        }
        guard lockScreenPair, size.width > 0, size.height > 0 else {
            return VerseStore.verse(for: date)
        }
        return VerseStore.verse(for: date) { verse in
            SplitLayout.fits(verse, columnWidth: size.width, height: size.height)
        }
    }
}
