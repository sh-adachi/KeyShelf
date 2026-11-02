import SwiftUI
import AppKit
import KeyShelfCore

@main
struct KeyShelfApp: App {
    @StateObject private var store = LibraryStore()
    var body: some Scene {
        Window("KeyShelf", id: "library") {
            ContentView().environmentObject(store)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1220, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("ショートカットを追加") { store.newShortcut() }.keyboardShortcut("n")
            }
            CommandGroup(after: .textEditing) {
                Button("ショートカットを検索") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }.keyboardShortcut("f")
            }
        }
        MenuBarExtra("KeyShelf", systemImage: "command.square") {
            QuickAccessView().environmentObject(store).preferredColorScheme(.light)
        }.menuBarExtraStyle(.window)
    }
}

extension Notification.Name {
    static let focusSearch = Notification.Name("KeyShelf.focusSearch")
}

struct QuickAccessView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.openWindow) private var openWindow
    @State private var query = ""
    @State private var favoritesOnly = false
    private var items: [Shortcut] {
        Array(ShortcutSearch.results(in: store.all, query: query, filter: favoritesOnly ? .favorites : .all,
                                    favorites: store.state.favorites).prefix(8))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("KeyShelf", systemImage: "command.square.fill").font(.headline)
                Spacer()
                Toggle(isOn: $favoritesOnly) { Image(systemName: "star.fill") }.toggleStyle(.button)
                    .help("お気に入りだけ表示")
            }
            TextField("名前やキーで検索", text: $query).textFieldStyle(.roundedBorder)
            if items.isEmpty {
                Text(favoritesOnly ? "お気に入りがありません" : "一致するショートカットがありません")
                    .foregroundStyle(.secondary).padding(.vertical, 20)
            }
            ForEach(items) { item in
                Button {
                    store.query = ""; store.filter = .all; store.selection = item.id
                    showLibrary()
                } label: {
                    HStack {
                        Text(item.title).lineLimit(1)
                        Spacer()
                        Text(item.keyLabel).font(.system(.body, design: .monospaced)).foregroundStyle(Palette.teal)
                    }.padding(.vertical, 5).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            Divider()
            HStack {
                Button("一覧を開く", action: showLibrary).buttonStyle(.borderedProminent).tint(Palette.teal)
                Spacer()
                Button("終了") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }.padding(20).frame(width: 360).background(Palette.paper)
    }
    private func showLibrary() {
        openWindow(id: "library")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
