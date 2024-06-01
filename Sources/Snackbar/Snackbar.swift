import SwiftUI

public struct SnackbarItemAction {
    var title: LocalizedStringKey
    var onTap: () -> Void

    public init(title: LocalizedStringKey, onTap: @escaping () -> Void) {
        self.title = title
        self.onTap = onTap
    }
}

public struct SnackbarItem: Equatable {
    var id = UUID().uuidString
    var text: LocalizedStringKey
    var duration: Double
    var showProgress: Bool
    var showCloseButton: Bool
    var action: SnackbarItemAction?

    public static func == (lhs: SnackbarItem, rhs: SnackbarItem) -> Bool {
        lhs.id == rhs.id
    }
}

public class SnackbarState: ObservableObject {
    @Published
    var pendingItems: [SnackbarItem] = []

    public static let shared = SnackbarState()
    public static let sheet = SnackbarState()

    public init() {}

    public func show(
        text: LocalizedStringKey,
        duration: Double = 1.5,
        showProgress: Bool = false,
        showCloseButton: Bool = false,
        action: SnackbarItemAction? = nil)
    {
        withAnimation {
            let item = SnackbarItem(text: text, duration: duration, showProgress: showProgress, showCloseButton: showCloseButton, action: action)
            pendingItems = [item]
        }
    }

    public func hide(item: SnackbarItem? = nil) {
        withAnimation {
            if let item {
                pendingItems.removeAll { $0 == item }
            } else {
                pendingItems = []
            }
        }
    }
}

struct Snackbar: View {
    @EnvironmentObject private var state: SnackbarState

    @Environment(\.colorScheme) var colorScheme

    var foregorundColor: Color {
        colorScheme == .dark ? Color(red: 38/255.0, green: 38/255.0, blue: 38/255.0) : .white
    }

    var backgroundColor: Color {
        colorScheme == .dark ? .white : Color(red: 38/255.0, green: 38/255.0, blue: 38/255.0)
    }

    var body: some View {
        if let item = state.pendingItems.first {
            HStack(spacing: 8) {
                if item.showProgress {
                    ProgressView()
                        .tint(foregorundColor)
                }

                Text(item.text)
                    .foregroundStyle(foregorundColor)

                Spacer()

                if let action = item.action {
                    Button(action.title) {
                        action.onTap()
                        state.hide(item: item)
                    }
                    .tint(foregorundColor)
                }

                if item.showCloseButton {
                    Button {
                        state.hide(item: item)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(foregorundColor)
                }
            }
            .padding()
            .frame(maxWidth: 450, alignment: .leading)
            .background(backgroundColor.shadow(.drop(radius: 6)))
            .clipShape(.rect(cornerRadius: 4))
            .padding()
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 32)
            }
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                if item.duration > 0 && !item.showProgress {
                    DispatchQueue.main.asyncAfter(deadline: .now() + item.duration) {
                        state.hide(item: item)
                    }
                }
            }
            .id(item.id)
        }
    }
}

public struct UseSnackbar: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            content

            Snackbar()
        }
    }
}

public extension View {
    func useSnackbar(_ state: SnackbarState = SnackbarState.shared) -> some View {
        modifier(UseSnackbar())
            .environmentObject(state)
    }

    func sheetWithSnackbar<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .useSnackbar(.sheet)
        }
    }

    func sheetWithSnackbar<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item: Identifiable, Content: View {
        sheet(item: item, onDismiss: onDismiss) {
            content($0)
                .useSnackbar(.sheet)
        }
    }
}
