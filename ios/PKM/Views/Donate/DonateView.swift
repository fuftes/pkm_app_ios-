import SwiftUI
import UIKit

/// Вкладка «Пожертва» (на сайті — «Жертводавцям»).
struct DonateView: View {
    @State private var copiedValue: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Brand.crimson)
                        Text(DonationInfo.project)
                            .font(.title2.bold())
                        Text("Дім для літніх людей, зал реабілітації для літніх і військових, місце духовної, фізичної та психологічної підтримки. Укриття вже завершено.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    NavigationLink("Звернення о. Йосафата") {
                        PageScreen(slug: "zhertvodavtsyam", title: "Жертводавцям")
                    }
                }

                Section {
                    LabeledContent("Отримувач", value: DonationInfo.recipient)
                    copyRow("Код ЄДРПОУ", DonationInfo.edrpou)
                    copyRow("IBAN", DonationInfo.iban)
                    LabeledContent("Банк", value: DonationInfo.bank)
                } header: {
                    Text("Рахунок монастиря")
                }

                Section {
                    copyRow("Картка", DonationInfo.card)
                    LabeledContent("На імʼя", value: DonationInfo.cardHolder)
                    copyRow("Призначення", DonationInfo.cardPurpose)
                } header: {
                    Text("Картка \(DonationInfo.cardBank)")
                } footer: {
                    Text("Торкніться рядка, щоб скопіювати.")
                }

                Section("Інші способи допомогти") {
                    Label("Молитися в наміренні нашої місії", systemImage: "hands.and.sparkles")
                    Label("Взяти конвертик при вході до храму", systemImage: "envelope")
                    Label("Допомогти працею, будматеріалами чи порадою", systemImage: "hammer")
                    Link(destination: AppConfig.phoneURL) {
                        Label("Подзвонити: \(AppConfig.phoneDisplay)", systemImage: "phone")
                    }
                }
            }
            .navigationTitle("Пожертва")
            .overlay(alignment: .bottom) {
                if let copiedValue {
                    Label("Скопійовано: \(copiedValue)", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sensoryFeedback(.success, trigger: copiedValue) { _, newValue in newValue != nil }
        }
    }

    private func copyRow(_ title: String, _ value: String) -> some View {
        Button {
            UIPasteboard.general.string = value.replacingOccurrences(of: " ", with: "")
            withAnimation { copiedValue = value }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { if copiedValue == value { copiedValue = nil } }
            }
        } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    Text(value)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.tint)
                }
            } label: {
                Text(title).foregroundStyle(.primary)
            }
        }
    }
}
