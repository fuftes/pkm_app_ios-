import SwiftUI
import WidgetKit

/// ТИМЧАСОВО: ручний вибір вірша для віджетів, щоб перевірити їх на своєму телефоні.
/// Перед публікацією застосунку прибрати цей екран і пункт у «Інше».
struct VerseTestView: View {
    @State private var chosenID: Int? = VerseStore.overrideID
    @State private var search = ""
    @State private var gap: CGFloat = VerseStore.widgetGap

    private var verses: [Verse] { VerseStore.all }

    /// Розмір віджета на заблокованому екрані. Відомий, коли віджет уже стоїть на екрані
    /// і App Group працює; інакше — приблизний.
    private var lockSize: CGSize { VerseStore.lockWidgetSize ?? CGSize(width: 160, height: 72) }
    private var lockSizeIsKnown: Bool { VerseStore.lockWidgetSize != nil }

    private var shownVerse: Verse {
        if let chosenID, let verse = VerseStore.verse(id: chosenID) { return verse }
        return VerseStore.verse(for: .now) { fits($0) }
    }

    private var filtered: [Verse] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return verses }
        return verses.filter {
            $0.text.localizedCaseInsensitiveContains(query) || $0.ref.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                PairPreview(verse: shownVerse, size: lockSize, gap: gap)
                    .listRowInsets(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(chosenID == nil ? "Режим: автоматично (вірш дня)" : "Режим: вибрано вручну")
                        .font(.subheadline.weight(.semibold))
                    Text("\(shownVerse.ref) · \(shownVerse.text.count) знаків")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !lockSizeIsKnown {
                        Text("Розмір віджета ще невідомий: додайте пару віджетів на заблокований екран і поверніться сюди.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Так виглядатиме пара на заблокованому екрані")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Проміжок між словами")
                        Spacer()
                        Text("\(Int(gap)) пт")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $gap, in: 4...30, step: 1, onEditingChanged: { editing in
                        if !editing { saveGap() }
                    })
                }
                Button("Скинути до \(Int(VerseStore.defaultWidgetGap)) пт") {
                    gap = VerseStore.defaultWidgetGap
                    saveGap()
                }
            } header: {
                Text("Проміжок")
            } footer: {
                Text("Підберіть так, щоб відстань між словами всередині рядка дорівнювала відстані між двома віджетами на заблокованому екрані. Надішліть число, яке підійшло, — я зашию його як стандартне.")
            }

            Section("Керування") {
                HStack {
                    Button {
                        step(by: -1)
                    } label: {
                        Label("Попередній", systemImage: "chevron.left")
                    }
                    Spacer()
                    Button {
                        step(by: 1)
                    } label: {
                        Label("Наступний", systemImage: "chevron.right")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                }
                .buttonStyle(.borderless)

                Button {
                    choose(verses.randomElement()?.id)
                } label: {
                    Label("Випадковий вірш", systemImage: "shuffle")
                }

                Button {
                    choose(nil)
                } label: {
                    Label("Повернути автоматичний режим", systemImage: "calendar")
                }
                .disabled(chosenID == nil)

                Button(role: .destructive) {
                    VerseStore.resetPersonalOrder()
                    choose(chosenID)
                } label: {
                    Label("Новий особистий порядок", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Усі вірші (\(filtered.count))") {
                ForEach(filtered) { verse in
                    Button {
                        choose(verse.id)
                    } label: {
                        VerseRow(verse: verse,
                                 isChosen: verse.id == chosenID,
                                 fits: fits(verse))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $search, prompt: "Пошук у віршах")
        .navigationTitle("Тест віджетів")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fits(_ verse: Verse) -> Bool {
        SplitLayout.fits(verse, columnWidth: lockSize.width, height: lockSize.height, gap: gap)
    }

    private func saveGap() {
        VerseStore.widgetGap = gap
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func step(by offset: Int) {
        let current = verses.firstIndex { $0.id == (chosenID ?? shownVerse.id) } ?? 0
        let next = (current + offset + verses.count) % verses.count
        choose(verses[next].id)
    }

    private func choose(_ id: Int?) {
        chosenID = id
        VerseStore.overrideID = id
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Дві половини поруч — як на заблокованому екрані.
private struct PairPreview: View {
    let verse: Verse
    let size: CGSize
    let gap: CGFloat

    var body: some View {
        // Відстань між половинами = проміжок між словами, як на заблокованому екрані.
        HStack(spacing: gap) {
            SplitHalfView(verse: verse, side: .left, gap: gap)
                .frame(width: size.width, height: size.height)
            SplitHalfView(verse: verse, side: .right, gap: gap)
                .frame(width: size.width, height: size.height)
        }
        .padding(10)
        .foregroundStyle(.white)
        .background(Color.black.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .environment(\.colorScheme, .dark)
        .frame(maxWidth: .infinity)
    }
}

private struct VerseRow: View {
    let verse: Verse
    let isChosen: Bool
    let fits: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isChosen ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isChosen ? Brand.crimson : Color.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(verse.text)
                    .font(.subheadline)
                    .lineLimit(3)
                HStack(spacing: 6) {
                    Text(verse.ref).fontWeight(.semibold)
                    Text("· \(verse.text.count) знаків")
                    if !fits {
                        Text("· не вміщається")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}
