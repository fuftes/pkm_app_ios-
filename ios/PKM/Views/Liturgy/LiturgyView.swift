import SwiftUI

/// Центральна вкладка «Літургія»: найближча служба, тижневий розклад, молитовні прохання, трансляції.
struct LiturgyView: View {
    private let schedule = LocalContent.schedule
    private let calendar = Calendar.kyiv

    /// Порядок днів у тижні: з понеділка (Calendar: 2…7, потім 1 — неділя).
    private let weekdays = [2, 3, 4, 5, 6, 7, 1]

    private static let sorokoustyFile = "sermons/2026-02-19-sorokousty-i-molinnia-za-pomerlykh-u-pkm-iak-zamovyty.md"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TimelineView(.everyMinute) { context in
                        NextServiceCard(next: schedule.nextService(after: context.date, calendar: calendar),
                                        now: context.date, calendar: calendar)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section("Розклад богослужінь") {
                    TimelineView(.everyMinute) { context in
                        let today = calendar.component(.weekday, from: context.date)
                        VStack(spacing: 0) {
                            ForEach(weekdays, id: \.self) { weekday in
                                DayRow(weekday: weekday,
                                       services: schedule.services(weekday: weekday),
                                       isToday: weekday == today,
                                       calendar: calendar)
                                if weekday != weekdays.last {
                                    Divider().padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Молитва") {
                    NavigationLink {
                        MessageFormView(kind: .prayerRequest)
                    } label: {
                        Label("Прохання про молитву", systemImage: "hands.and.sparkles")
                    }
                    if let sermon = LocalContent.sermon(file: Self.sorokoustyFile) {
                        NavigationLink {
                            SermonDetailView(sermon: sermon)
                        } label: {
                            Label("Сорокоусти і моління за померлих", systemImage: "flame")
                        }
                    }
                }

                Section("Онлайн") {
                    Link(destination: AppConfig.youtubeChannel) {
                        Label("Трансляції та відео на YouTube", systemImage: "play.rectangle")
                    }
                    Link(destination: AppConfig.facebook) {
                        Label("Сторінка у Facebook", systemImage: "person.2")
                    }
                }
            }
            .navigationTitle("Літургія")
        }
    }
}

private struct NextServiceCard: View {
    let next: (date: Date, service: WeekSchedule.Service)?
    let now: Date
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Найближча служба")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            if let next {
                Text(next.service.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("\(dayLabel(next.date)), \(next.service.time)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("Розклад уточнюється")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Label(AppConfig.address, systemImage: "mappin.and.ellipse")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Brand.crimson, Brand.crimson.opacity(0.75)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func dayLabel(_ date: Date) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Сьогодні" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Завтра"
        }
        return WeekdayName.full(calendar.component(.weekday, from: date)).capitalized
    }
}

private struct DayRow: View {
    let weekday: Int
    let services: [WeekSchedule.Service]
    let isToday: Bool
    let calendar: Calendar

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(WeekdayName.full(weekday).capitalized)
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(isToday ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if services.isEmpty {
                    Text("—").foregroundStyle(.secondary)
                }
                ForEach(services, id: \.self) { service in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(service.time)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                        Text(service.title)
                            .font(.subheadline)
                            .foregroundStyle(service.kind == "liturgy" ? .primary : .secondary)
                    }
                }
            }
        }
    }
}

enum WeekdayName {
    /// 1 — неділя … 7 — субота (як у Calendar).
    static func full(_ weekday: Int) -> String {
        ["неділя", "понеділок", "вівторок", "середа", "четвер", "пʼятниця", "субота"][(weekday - 1) % 7]
    }
}
