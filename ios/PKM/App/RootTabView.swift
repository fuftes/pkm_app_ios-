import SwiftUI

/// П'ять вкладок унизу; «Літургія» — посередині.
/// Зібраний у Xcode 26 і запущений на iOS 26, стандартний TabView сам отримує панель Liquid Glass.
struct RootTabView: View {
    enum TabID: Hashable {
        case news, reading, liturgy, donate, more
    }

    @State private var selection: TabID = .liturgy

    var body: some View {
        TabView(selection: $selection) {
            Tab("Новини", systemImage: "newspaper", value: TabID.news) {
                NewsView()
            }
            Tab("Читання", systemImage: "book", value: TabID.reading) {
                ReadingView()
            }
            Tab("Літургія", systemImage: "building.columns", value: TabID.liturgy) {
                LiturgyView()
            }
            Tab("Пожертва", systemImage: "heart", value: TabID.donate) {
                DonateView()
            }
            Tab("Інше", systemImage: "ellipsis.circle", value: TabID.more) {
                MoreView()
            }
        }
        .modifier(LiquidGlassTabBar())
    }
}

/// Налаштування, доступні лише на iOS 26+: панель вкладок зменшується, коли гортаєш униз.
private struct LiquidGlassTabBar: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
