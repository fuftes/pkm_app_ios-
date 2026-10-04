import SwiftUI

/// Горизонтальний ряд «чипів» для перемикання підрозділів (Усі · Парафія · УГКЦ …).
struct Chip<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
}

struct ChipBar<ID: Hashable>: View {
    let items: [Chip<ID>]
    @Binding var selection: ID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = item.id == selection
                    Button {
                        withAnimation(.snappy) { selection = item.id }
                    } label: {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.thinMaterial), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

extension View {
    /// Закріплює ряд чипів угорі під навігаційною панеллю; вміст прокручується під ним.
    func chipBar<ID: Hashable>(_ items: [Chip<ID>], selection: Binding<ID>) -> some View {
        modifier(ChipBarModifier(items: items, selection: selection))
    }
}

private struct ChipBarModifier<ID: Hashable>: ViewModifier {
    let items: [Chip<ID>]
    @Binding var selection: ID

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            // iOS 26: панель отримує ефект Liquid Glass «краю прокрутки», як системні бари.
            content.safeAreaBar(edge: .top, spacing: 0) {
                ChipBar(items: items, selection: $selection)
            }
        } else {
            legacy(content)
        }
        #else
        legacy(content)
        #endif
    }

    private func legacy(_ content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            ChipBar(items: items, selection: $selection)
                .background(.bar)
        }
    }
}
