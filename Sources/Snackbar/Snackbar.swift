import SwiftUI

#if canImport(UIKit) && canImport(SwiftUIIntrospect)
import SwiftUIIntrospect
#endif

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
    var bottomInset: CGFloat?
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
    public static let fullScreenCover = SnackbarState()

    public init() {}

    public func show(
        text: LocalizedStringKey,
        duration: Double = 1.5,
        showProgress: Bool = false,
        showCloseButton: Bool = false,
        bottomInset: CGFloat? = nil,
        action: SnackbarItemAction? = nil)
    {
        withAnimation {
            let item = SnackbarItem(text: text, duration: duration, showProgress: showProgress, showCloseButton: showCloseButton, bottomInset: bottomInset, action: action)
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

    @State private var childSafeAreaBottomInset: CGFloat = 0

    var body: some View {
        Group {
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
                .safeAreaPadding(.bottom, item.bottomInset ?? childSafeAreaBottomInset)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
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
#if canImport(UIKit) && canImport(SwiftUIIntrospect)
        .introspect(.viewController, on: .iOS(.v17...)) { viewController in
            let tabBarController = viewController as? UITabBarController
                ?? viewController.tabBarController
                ?? viewController.children.compactMap { $0 as? UITabBarController }.first
            guard let safeAreaView = tabBarController?.selectedViewController?.view
                ?? viewController.view
            else { return }

            let bottomInset = safeAreaView.safeAreaInsets.bottom
            guard bottomInset != childSafeAreaBottomInset else { return }

            DispatchQueue.main.async {
                guard bottomInset != childSafeAreaBottomInset else { return }
                childSafeAreaBottomInset = bottomInset
            }
        }
#endif
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

    func sheetWithSnackbar<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .useSnackbar(.sheet)
        }
    }

    func sheetWithSnackbar<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        sheet(item: item, onDismiss: onDismiss) {
            content($0)
                .useSnackbar(.sheet)
        }
    }

    func fullScreenCoverWithSnackbar<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .useSnackbar(.fullScreenCover)
        }
    }

    func fullScreenCoverWithSnackbar<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) {
            content($0)
                .useSnackbar(.fullScreenCover)
        }
    }
}
