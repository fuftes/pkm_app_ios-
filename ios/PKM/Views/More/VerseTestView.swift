import SwiftUI
import WidgetKit

/// ТИМЧАСОВО: перевірка віджета «Слово на день» на заблокованому екрані.
/// 1) Вимірювання: на віджеті випадкові символи заданої довжини — видно, скільки вміщається.
/// 2) Вибір будь-якого вірша вручну.
/// Перед публікацією застосунку прибрати цей екран і пункт у «Інше».
struct VerseTestView: View {
    @State private var measuring = VerseStore.measureEnabled
    @State private var length = VerseStore.measureLength
    @State private var withReference = VerseStore.showReference
    @State private var withDash = VerseStore.showDash
    @State private var autoFont = VerseStore.autoFont
    @State private var fontSize = VerseStore.lockFontSize
    @State private var chosenID: Int? = VerseStore.overrideID
    @State private var search = ""

    /// Усі вірші від найкоротших до найдовших (за кількістю знаків у тексті).
    private var verses: [Verse] {
        VerseStore.all.sorted { ($0.text.count, $0.id) < ($1.text.count, $1.id) }
    }

    /// Розмір віджета. Відомий, коли віджет уже стоїть на заблокованому екрані; інакше — приблизний.
    private var lockSize: CGSize { VerseStore.lockWidgetSize ?? CGSize(width: 160, height: 72) }
    private var lockSizeIsKnown: Bool { VerseStore.lockWidgetSize != nil }

    private var shownVerse: Verse {
        if let chosenID, let verse = VerseStore.verse(id: chosenID) { return verse }
        return VerseStore.verse(for: .now) { fits($0) }
    }

    private var previewContent: LockContent {
        measuring
            ? .filler(length: length, withReference: withReference, withDash: withDash)
            : .verse(shownVerse, withReference: withReference, withDash: withDash)
    }

    private var calculatedMax: Int {
        LockFit.maxLength(in: lockSize, maxSize: fontSize, auto: autoFont,
                          withReference: withReference, withDash: withDash)
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
                LockTextView(content: previewContent, maxFontSize: fontSize, autoFont: autoFont)
                    .frame(width: lockSize.width, height: lockSize.height)
                    .padding(12)
                    .foregroundStyle(.white)
                    .background(Color.black.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .environment(\.colorScheme, .dark)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Розмір віджета: \(Int(lockSize.width)) × \(Int(lockSize.height)) пт"
                         + (lockSizeIsKnown ? "" : " (приблизно)"))
                    Text("За розрахунком вміщається до \(calculatedMax) знаків тексту"
                         + (withReference ? " + посилання" : ""))
                    if !lockSizeIsKnown {
                        Text("Додайте віджет «Слово на день» на заблокований екран і поверніться сюди — тоді розмір буде точний.")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("Попередній перегляд")
            }

            Section {
                Toggle("Режим вимірювання", isOn: $measuring)
                    .onChange(of: measuring) { save() }

                HStack {
                    Text("Знаків тексту")
                    Spacer()
                    Text("\(length)")
                        .monospacedDigit()
                        .font(.title3.weight(.semibold))
                }
                HStack(spacing: 10) {
                    StepButton(title: "−10") { change(by: -10) }
                    StepButton(title: "−1") { change(by: -1) }
                    StepButton(title: "+1") { change(by: 1) }
                    StepButton(title: "+10") { change(by: 10) }
                }
                .disabled(!measuring)

                Toggle("Показувати посилання", isOn: $withReference)
                    .onChange(of: withReference) { save() }
                if withReference {
                    Toggle("Тире перед посиланням (—)", isOn: $withDash)
                        .onChange(of: withDash) { save() }
                    let longest = LockContent.longestReference(withDash: withDash)
                    Text("У вимірюванні — найдовше: «\(longest)», \(longest.count) знаків.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Шрифт підбирається сам", isOn: $autoFont)
                    .onChange(of: autoFont) { save() }
                Stepper(value: $fontSize, in: 11...22, step: 1) {
                    Text(autoFont
                         ? "Найбільший шрифт: \(Int(fontSize)) пт (зменшується до \(Int(VerseStore.minLockFontSize)))"
                         : "Шрифт: \(Int(fontSize)) пт")
                }
                .onChange(of: fontSize) { save() }
            } header: {
                Text("Вимірювання місткості")
            } footer: {
                Text("Увімкніть режим, заблокуйте телефон і дивіться на віджет. Додавайте знаки, доки текст не обріжеться «…». Остання кількість без «…» — і є місткість. З автопідбором шрифту це місткість при найменшому шрифті (11 пт); без нього — при вибраному. Надішліть мені число разом із моделлю iPhone.")
            }

            Section("Вірш вручну") {
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
                        HStack(spacing: 6) {
                            Text("Наступний")
                            Image(systemName: "chevron.right")
                        }
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

            Section("Усі вірші — від найкоротших (\(filtered.count))") {
                ForEach(filtered) { verse in
                    Button {
                        choose(verse.id)
                    } label: {
                        VerseRow(verse: verse, isChosen: verse.id == chosenID, fits: fits(verse))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $search, prompt: "Пошук у віршах")
        .navigationTitle("Тест віджета")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fits(_ verse: Verse) -> Bool {
        LockFit.fits(verse, in: lockSize, maxSize: fontSize, auto: autoFont,
                     withReference: withReference, withDash: withDash)
    }

    private func change(by delta: Int) {
        length = min(400, max(1, length + delta))
        save()
    }

    private func step(by offset: Int) {
        let current = verses.firstIndex { $0.id == (chosenID ?? shownVerse.id) } ?? 0
        let next = (current + offset + verses.count) % verses.count
        choose(verses[next].id)
    }

    private func choose(_ id: Int?) {
        chosenID = id
        measuring = false
        save()
    }

    private func save() {
        VerseStore.measureEnabled = measuring
        VerseStore.measureLength = length
        VerseStore.showReference = withReference
        VerseStore.showDash = withDash
        VerseStore.autoFont = autoFont
        VerseStore.lockFontSize = fontSize
        VerseStore.overrideID = chosenID
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct StepButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
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
