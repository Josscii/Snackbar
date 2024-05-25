### The Missing HUD/Toast/Snackbar in iOS

#### How to Implement It in SwiftUI

Whenever I build an app, I always look for a HUD/toast/snackbar component because Apple doesn't officially provide one. Apple does use such designs in apps like AppStore Music, but they haven't clearly defined them. It seems Apple might not favor this approach. However, apps sometimes need this kind of feedback element for users, so I strongly suggest that Apple consider adding such a component.

I've seen a kind of snackbar displayed at the bottom of the page in many iOS apps, such as Spotify. This snackbar looks great, and there is a similar design in Material Design.

Let's see how to implement a simple snackbar in SwiftUI.

First, let's think about how to design the interface, so that developers (including myself) can easily use it.

Considering my usual coding scenarios, I want to be able to invoke a snackbar with a single line of code, possibly in a View or in a ViewModel. This might be achieved with a singleton.

Therefore, the code to show/hide a snackbar might look like this:

```swift
SnackbarState.shared.show(text: "This is a snackbar!")
SnackbarState.shared.hide()
```

Next, we need to think about the configurable content of the snackbar. For now, we will implement some simple configurations:

- text (prompt text)
- duration (display duration)
- showProgress (whether to show loading)
- showCloseButton (whether to show the close button)
- ...

Now we need to create a model for the snackbar to store these configurations. I will temporarily name it `SnackbarItem`:

```swift
public struct SnackbarItem: Equatable {
    var id = UUID().uuidString
    var text: LocalizedStringKey
    var duration: Double
    var showProgress: Bool
    var showCloseButton: Bool
}
```

When we call the `show` method of `SnackbarState`, we need to create a new `SnackbarItem` and store it for display:

```swift
public func show(text: LocalizedStringKey, duration: Double = 1.5, showProgress: Bool = false, showCloseButton: Bool = false) {
    withAnimation {
        let item = SnackbarItem(text: text, duration: duration, showProgress: showProgress, showCloseButton: showCloseButton)
        pendingItems = [item]
    }
}
```

This uses an array `pendingItems` to facilitate future expansion because there may be situations where multiple snackbars are displayed.

Here is our `hide` method, which takes a `SnackbarItem` to hide its corresponding snackbar, or hide all snackbars.

```swift
public func hide(item: SnackbarItem? = nil) {
    withAnimation {
        if let item {
            pendingItems.removeAll { $0 == item }
        } else {
            pendingItems = []
        }
    }
}
```

Now let's take a look at the full view of `SnackbarState`, which we define as an `ObservableObject` so that the snackbar can listen to its changes.

```swift
public class SnackbarState: ObservableObject {
    public struct SnackbarItem: Equatable {
        var id = UUID().uuidString
        var text: LocalizedStringKey
        var duration: Double
        var showProgress: Bool
        var showCloseButton: Bool
    }

    @Published
    var pendingItems: [SnackbarItem] = []

    public static let shared = SnackbarState()

    public init() {}

    public func show(
        text: LocalizedStringKey,
        duration: Double = 1.5,
        showProgress: Bool = false,
        showCloseButton: Bool = false)
    {
        withAnimation {
            let item = SnackbarItem(text: text, duration: duration, showProgress: showProgress, showCloseButton: showCloseButton)
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
```

Next, let's think about how the snackbar should be displayed in the interface.

Obviously, the snackbar should be displayed on top of all Views. Therefore, we define a `ViewModifier` like this:

```swift
public struct UseSnackbar: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            content

            Snackbar()
        }
    }
}
```

Then define an extension method for the View to use this `ViewModifier`:

```swift
public extension View {
    func useSnackbar(_ state: SnackbarState = SnackbarState.shared) -> some View {
        modifier(UseSnackbar())
            .environmentObject(state)
    }
}
```

We pass in the previously defined `SnackbarState` through `environmentObject` (default to `shared`), so that the snackbar can access the state.

Let's implement the snackbar:

```swift
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

                if item.showCloseButton {
                    Spacer()

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
```

We get the state through `EnvironmentObject`. If there is a `SnackbarItem` that needs to be displayed, then show it; otherwise, show nothing.

It is worth noting that the id of `SnackbarItem` comes in handy here. We set it as the id of the view. Each time the id changes, the view will be rebuilt, and the `transition` and `onAppear` will be called again.

Now let's use the snackbar:

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            Button("Show") {
                SnackbarState.shared.show(text: "Hello, world!")
            }
        }
        .padding()
        .useSnackbar()
    }
}
```

We apply `useSnackbar` to the outermost content view, and then call `show` anywhere in the app to display our snackbar. It looks pretty good.

**But here we actually overlooked a special case: in SwiftUI, `sheet` covers the content view, which means we cannot display a snackbar in the `sheet`!**

I have seen others combine UIKit's window to solve this problem, which requires writing some rather hacky code. That's not what I want.

Here's how I solved this problem:

I added a singleton `sheet` to `SnackbarState` to manage the state of displaying the snackbar in the sheet.

```swift
class SnackbarState: ObservableObject {
    ...
    public static let sheet = SnackbarState()
    ...
}
```

Then extended the View with `sheetWithSnackbar` to use this state.

```swift
public extension View {
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
```

This way, the sheet can also display its own snackbar.

Another issue is that if a View might be used both in the content view and in the sheet, it seems we need some judgment to decide whether to call the shared or the sheet singleton. It is inconvenient, but actually, using `EnvironmentObject` to get `SnackbarState` solves this.

```swift
struct SomeView: View {
    @EnvironmentObject var snackbarState: SnackbarState

    var body: some View {
        Button("Show Snackbar") {
            snackbarState.show(text: "This is a snackbar!")
        }
    }
}
```

At this point, we have basically completed the construction of the snackbar. Of course, there are many areas for improvement:

- Provide more configuration options for the snackbar
- Define the display behavior of multiple snackbars, directly replace or enter the queue
- Add gestures to hide the snackbar
- Add action buttons to the snackbar

That's all the content. I hope it can give you some inspiration.
