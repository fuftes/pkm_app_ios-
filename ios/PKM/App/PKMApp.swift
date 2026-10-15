import SwiftUI

@main
struct PKMApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, Locale(identifier: "uk_UA"))
        }
    }
}
