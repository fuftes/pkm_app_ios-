import SwiftUI
import UIKit

/// Форма «Прохання про молитву» / «Запитай священника».
/// Поки немає сервера — готує лист у поштовому застосунку на адресу настоятеля.
struct MessageFormView: View {
    enum Kind {
        case prayerRequest, askPriest

        var title: String {
            switch self {
            case .prayerRequest: "Прохання про молитву"
            case .askPriest: "Запитай священника"
            }
        }
    }

    enum Intention: String, CaseIterable, Identifiable {
        case health = "За здоровʼя"
        case repose = "За упокій"
        case thanks = "Подяка"
        case other = "Інше"

        var id: String { rawValue }
    }

    let kind: Kind

    @Environment(\.openURL) private var openURL
    @State private var name = ""
    @State private var intention: Intention = .health
    @State private var names = ""
    @State private var message = ""
    @State private var showMailFallback = false

    var body: some View {
        Form {
            Section {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Від кого") {
                TextField("Ваше імʼя (необовʼязково)", text: $name)
                    .textContentType(.name)
            }

            if kind == .prayerRequest {
                Section("Намір") {
                    Picker("Намір", selection: $intention) {
                        ForEach(Intention.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    TextField("За кого молитися (імена)", text: $names, axis: .vertical)
                        .lineLimit(1...4)
                }
            }

            Section(kind == .prayerRequest ? "Прохання" : "Ваше питання") {
                TextField(kind == .prayerRequest ? "Опишіть прохання" : "Напишіть питання",
                          text: $message, axis: .vertical)
                    .lineLimit(5...12)
            }

            Section {
                Button(action: send) {
                    Label("Надіслати", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSend)
            } footer: {
                Text("Відкриється поштовий застосунок з готовим листом на \(AppConfig.priestEmail).")
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Не вдалося відкрити пошту", isPresented: $showMailFallback) {
            Button("Скопіювати текст") { UIPasteboard.general.string = mailBody }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Скопіюйте текст і надішліть його на \(AppConfig.priestEmail) або в месенджері на \(AppConfig.phoneDisplay).")
        }
    }

    private var intro: String {
        switch kind {
        case .prayerRequest:
            "Священники парафії помоляться у Ваших наміреннях під час Божественної Літургії та Вервиці."
        case .askPriest:
            "Поставте питання про віру, таїнства чи життя парафії — священник відповість Вам особисто."
        }
    }

    private var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (kind == .prayerRequest && !names.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var mailBody: String {
        var lines: [String] = []
        if kind == .prayerRequest {
            lines.append("Намір: \(intention.rawValue)")
            if !names.isEmpty { lines.append("За кого: \(names)") }
            lines.append("")
        }
        lines.append(message)
        lines.append("")
        lines.append(name.isEmpty ? "Надіслано із застосунку парафії" : "\(name)\n(надіслано із застосунку парафії)")
        return lines.joined(separator: "\n")
    }

    private func send() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConfig.priestEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: kind.title),
            URLQueryItem(name: "body", value: mailBody),
        ]
        guard let url = components.url else { return }
        openURL(url) { accepted in
            if !accepted { showMailFallback = true }
        }
    }
}
