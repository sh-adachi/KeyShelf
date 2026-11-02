import SwiftUI
import KeyShelfCore

struct ContentView: View {
    @EnvironmentObject private var store: LibraryStore
    @FocusState private var searchFocused: Bool
    @State private var showGuide = false
    @State private var deleteTarget: Shortcut?

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 218)
            VStack(spacing: 0) {
                header
                Rectangle().fill(Palette.line).frame(height: 1)
                HStack(spacing: 0) {
                    shortcutList.frame(minWidth: 425, maxWidth: .infinity)
                    Rectangle().fill(Palette.line).frame(width: 1)
                    detail.frame(width: 302)
                }
            }.background(Palette.paper)
        }
        .frame(minWidth: 990, minHeight: 660)
        .tint(Palette.teal)
        .foregroundStyle(Palette.ink)
        .sheet(item: $store.editor) { item in ShortcutEditor(item: item).environmentObject(store) }
        .sheet(isPresented: $showGuide) { GuideView() }
        .alert("保存に関するお知らせ", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .alert("このショートカットを削除しますか？", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("キャンセル", role: .cancel) { deleteTarget = nil }
            Button("削除", role: .destructive) { if let item = deleteTarget { store.delete(item) }; deleteTarget = nil }
        } message: { Text(deleteTarget?.title ?? "") }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in searchFocused = true }
        .onChange(of: store.results.map(\.id)) { _, _ in store.reconcileSelection() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "command").font(.system(size: 23, weight: .medium))
                    .frame(width: 38, height: 38).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text("KeyShelf").font(.system(size: 21, weight: .semibold, design: .rounded))
                    Text("MAC SHORTCUT LIBRARY").font(.system(size: 7.5, weight: .medium)).tracking(1.2).foregroundStyle(.white.opacity(0.5))
                }
            }.padding(.horizontal, 20).padding(.top, 48).padding(.bottom, 31)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("ライブラリ")
                    navRow(.all, "square.grid.2x2", "すべて")
                    navRow(.favorites, "star", "お気に入り")
                    navRow(.custom, "person.crop.square", "マイショートカット")
                    sectionLabel("カテゴリ").padding(.top, 27)
                    ForEach(ShortcutCategory.allCases) { category in
                        navRow(.category(category), category.symbol, category.title)
                    }
                }
            }.scrollIndicators(.hidden)
            Spacer(minLength: 16)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "lightbulb").font(.system(size: 18)).foregroundStyle(Color(red: 0.85, green: 0.88, blue: 0.55))
                Text("小さなキーで、大きな時短。").font(.system(size: 11, weight: .medium))
                Text("よく使う操作を☆に保存して、\n少しずつ自分のものに。").font(.system(size: 10)).foregroundStyle(.white.opacity(0.55)).lineSpacing(4)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16)
            Button { showGuide = true } label: {
                Label("キー記号のガイド", systemImage: "questionmark.circle").font(.system(size: 11))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(22)
            }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.65))
        }
        .foregroundStyle(.white)
        .background(Palette.sidebar)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.40))
            .padding(.horizontal, 25).padding(.bottom, 9)
    }
    private func navRow(_ filter: LibraryFilter, _ symbol: String, _ title: String) -> some View {
        let active = store.filter == filter
        return Button { store.navigate(filter) } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 14)).frame(width: 18)
                Text(title).font(.system(size: 11.5, weight: active ? .semibold : .regular)).lineLimit(1)
                Spacer(minLength: 2)
                Text("\(store.count(filter))").font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.white.opacity(active ? 0.85 : 0.35))
            }.padding(.horizontal, 12).frame(height: 39)
                .background(active ? .white.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(.white.opacity(active ? 1 : 0.65)).padding(.horizontal, 12)
            .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 23) {
            HStack {
                HStack(spacing: 5) {
                    Text("ライブラリ").foregroundStyle(Palette.muted)
                    Image(systemName: "chevron.right").font(.system(size: 8))
                    Text(store.filter == .all ? "すべて" : store.filter.title)
                }.font(.system(size: 10))
                Spacer()
                Text("FOR YOUR EVERYDAY FLOW").font(.system(size: 8, weight: .medium)).tracking(1.7).foregroundStyle(Palette.muted)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(store.filter.title).font(.system(size: 25, weight: .bold))
                        Text("\(store.count(store.filter))").font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.teal).padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Palette.mint, in: Capsule())
                    }
                    Text("探す時間を、つくる時間に。").font(.system(size: 11)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 10)
                Button { store.newShortcut() } label: {
                    Label("追加する", systemImage: "plus").font(.system(size: 11, weight: .medium)).padding(.horizontal, 8).padding(.vertical, 6)
                }.buttonStyle(.borderedProminent).tint(Palette.teal).help("マイショートカットを追加（⌘N）")
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 15)).foregroundStyle(Palette.teal)
                TextField("操作名、アプリ、キーで検索…", text: $store.query).textFieldStyle(.plain)
                    .font(.system(size: 12)).focused($searchFocused).accessibilityIdentifier("library.search")
                if !store.query.isEmpty {
                    Button { store.query = ""; searchFocused = true } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(Palette.muted).help("検索をクリア")
                }
                Text("⌘ F").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
                    .padding(.horizontal, 6).padding(.vertical, 4).background(Palette.paper, in: RoundedRectangle(cornerRadius: 4))
            }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.line, lineWidth: 1))
        }.padding(.horizontal, 29).padding(.top, 36).padding(.bottom, 22)
    }

    private var shortcutList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(store.query.isEmpty ? "ショートカット一覧" : "検索結果").font(.system(size: 10, weight: .medium))
                Text("\(store.results.count)件").font(.system(size: 10)).foregroundStyle(Palette.muted)
                Spacer()
                Menu {
                    Button("おすすめ順") { store.sortByName = false }
                    Button("名前順") { store.sortByName = true }
                } label: {
                    Label(store.sortByName ? "名前順" : "おすすめ順", systemImage: "arrow.up.arrow.down").font(.system(size: 10))
                }.menuStyle(.borderlessButton).fixedSize()
            }.padding(.horizontal, 27).padding(.vertical, 16)
            if store.results.isEmpty {
                emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $store.selection) {
                    ForEach(store.results) { item in
                        ShortcutRow(item: item).environmentObject(store)
                            .tag(item.id)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                            .contextMenu {
                                Button(store.state.favorites.contains(item.id) ? "お気に入りを解除" : "お気に入りに追加") { store.toggleFavorite(item) }
                                Button("名前とキーをコピー") { store.copy(item) }
                                if item.isCustom {
                                    Button("編集") { store.editor = item }
                                    Button("削除", role: .destructive) { deleteTarget = item }
                                }
                            }
                    }
                }.listStyle(.plain).scrollContentBackground(.hidden).padding(.horizontal, 12)
            }
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text("アプリやキーボードの設定によって、操作が異なる場合があります。")
            }.font(.system(size: 9)).foregroundStyle(Palette.muted).padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: store.query.isEmpty ? "star" : "magnifyingglass").font(.system(size: 32, weight: .light)).foregroundStyle(Palette.teal)
            Text(store.query.isEmpty ? (store.filter == .custom ? "自分だけの早見表をつくろう" : "よく使う操作を、ここに。") : "一致するショートカットがありません")
                .font(.system(size: 15, weight: .semibold))
            Text(store.query.isEmpty ? "☆で保存するか、追加ボタンから登録できます。" : "短い言葉や「cmd」「スクショ」でも検索できます。")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
            if store.query.isEmpty && store.filter == .custom {
                Button("ショートカットを追加") { store.newShortcut() }.buttonStyle(.bordered)
            } else if !store.query.isEmpty {
                Button("検索をクリア") { store.query = "" }.buttonStyle(.bordered)
            }
        }.padding(20)
    }

    @ViewBuilder private var detail: some View {
        if let item = store.selected {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    HStack {
                        Text("SHORTCUT NOTE").font(.system(size: 8, weight: .semibold)).tracking(1.8).foregroundStyle(Palette.muted)
                        Spacer()
                        Image(systemName: item.category.symbol).foregroundStyle(Palette.teal)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.scope).font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.teal)
                        Text(item.title).font(.system(size: 22, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(spacing: 19) {
                        ViewThatFits {
                            KeyCaps(keys: item.keys, large: true)
                            KeyCaps(keys: item.keys)
                        }
                        Text(item.keys.count > 1 ? "修飾キーを押しながら、最後のキーを押す" : "項目を選択して、キーを押す")
                            .font(.system(size: 9)).foregroundStyle(Palette.muted)
                    }.frame(maxWidth: .infinity).padding(.vertical, 26)
                        .background(Palette.mint.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 10) {
                        Text("使い方のヒント").font(.system(size: 11, weight: .semibold))
                        Text(item.note.isEmpty ? "\(item.scope)で「\(item.title)」を使うためのキーです。" : item.note)
                            .font(.system(size: 12)).foregroundStyle(Palette.muted).lineSpacing(6).textSelection(.enabled)
                    }
                    VStack(spacing: 9) {
                        Button { store.toggleFavorite(item) } label: {
                            Label(store.state.favorites.contains(item.id) ? "お気に入りに保存済み" : "お気に入りに追加", systemImage: store.state.favorites.contains(item.id) ? "star.fill" : "star")
                                .font(.system(size: 11, weight: .medium)).frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.bordered).tint(Palette.teal)
                        Button { store.copy(item) } label: {
                            Label(store.copiedID == item.id ? "コピーしました" : "名前とキーをコピー", systemImage: store.copiedID == item.id ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11)).frame(maxWidth: .infinity).padding(.vertical, 7)
                        }.buttonStyle(.bordered)
                    }
                    Rectangle().fill(Palette.line).frame(height: 1)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("キーの読み方").font(.system(size: 10, weight: .semibold))
                        ForEach(item.keys.filter { ["⌘", "⌥", "⇧", "⌃", "⇥", "⌫", "⎋"].contains($0) }, id: \.self) { key in
                            HStack {
                                Text(key).font(.system(size: 17)).frame(width: 24)
                                Text(keyName(key)).font(.system(size: 11)).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                    if let url = item.sourceURL {
                        Link(destination: url) { Label("Apple公式リファレンス", systemImage: "arrow.up.right").font(.system(size: 10)) }
                            .foregroundStyle(Palette.teal)
                    } else {
                        HStack {
                            Button("編集する") { store.editor = item }
                            Spacer()
                            Button("削除", role: .destructive) { deleteTarget = item }
                        }.font(.system(size: 11))
                    }
                }.padding(25).padding(.top, 4)
            }.background(Color.white.opacity(0.55))
        } else {
            VStack(spacing: 13) {
                Image(systemName: "command.square").font(.system(size: 38, weight: .ultraLight))
                Text("ショートカットを選択").font(.system(size: 12))
            }.foregroundStyle(Palette.muted).frame(maxHeight: .infinity)
        }
    }
    private func keyName(_ key: String) -> String {
        ["⌘": "Command", "⌥": "Option", "⇧": "Shift", "⌃": "Control", "⇥": "Tab", "⌫": "Delete", "⎋": "Escape"][key] ?? key
    }
}

struct ShortcutRow: View {
    let item: Shortcut
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.controlActiveState) private var controlActiveState
    private var highlighted: Bool { store.selection == item.id && controlActiveState != .inactive }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.symbol).font(.system(size: 15, weight: .regular))
                .foregroundStyle(Palette.teal).frame(width: 36, height: 36)
                .background(Palette.mint.opacity(0.65), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 12, weight: .medium)).foregroundStyle(highlighted ? .white : Palette.ink).lineLimit(1)
                Text(item.scope).font(.system(size: 9)).foregroundStyle(highlighted ? .white.opacity(0.8) : Palette.muted).lineLimit(1)
            }
            Spacer(minLength: 5)
            KeyCaps(keys: item.keys)
            Button { store.toggleFavorite(item) } label: {
                Image(systemName: store.state.favorites.contains(item.id) ? "star.fill" : "star")
                    .font(.system(size: 13)).foregroundStyle(store.state.favorites.contains(item.id) ? Color(red: 0.69, green: 0.52, blue: 0.18) : Palette.muted.opacity(0.5))
                    .frame(width: 26, height: 32).contentShape(Rectangle())
            }.buttonStyle(.borderless).help(store.state.favorites.contains(item.id) ? "お気に入りを解除" : "お気に入りに追加")
                .accessibilityLabel("\(item.title)をお気に入り\(store.state.favorites.contains(item.id) ? "から解除" : "に追加")")
        }.padding(.vertical, 9).padding(.horizontal, 6)
    }
}
