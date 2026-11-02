import SwiftUI
import KeyShelfCore

struct ShortcutEditor: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    private let original: Shortcut
    @State private var title: String
    @State private var app: String
    @State private var category: ShortcutCategory
    @State private var note: String
    @State private var modifiers: Set<String>
    @State private var key: String
    @State private var saveError: String?
    private let modifierOrder = ["⌃", "⌥", "⇧", "⌘"]

    init(item: Shortcut) {
        original = item
        _title = State(initialValue: item.title)
        _app = State(initialValue: item.customApp ?? "")
        _category = State(initialValue: item.category)
        _note = State(initialValue: item.note)
        _modifiers = State(initialValue: Set(item.keys.filter { ["⌃", "⌥", "⇧", "⌘"].contains($0) }))
        _key = State(initialValue: item.keys.last(where: { !["⌃", "⌥", "⇧", "⌘"].contains($0) }) ?? "")
    }
    private var cleanTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanKey: String {
        let value = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let aliases = ["space": "Space", "tab": "⇥", "return": "⏎", "enter": "⏎", "delete": "⌫", "esc": "⎋", "escape": "⎋", "left": "←", "right": "→", "up": "↑", "down": "↓"]
        return aliases[value.lowercased()] ?? (value.count == 1 ? value.uppercased() : value)
    }
    private var keys: [String] { modifierOrder.filter { modifiers.contains($0) } + (cleanKey.isEmpty ? [] : [cleanKey]) }
    private var valid: Bool { !cleanTitle.isEmpty && cleanTitle.count <= 80 && !cleanKey.isEmpty && cleanKey.count <= 16 && !modifierOrder.contains(cleanKey) && app.count <= 80 && note.count <= 1000 }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(original.title.isEmpty ? "ショートカットを追加" : "ショートカットを編集").font(.system(size: 22, weight: .bold))
                    Text("自分のアプリや、変更したキーをメモできます。").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Image(systemName: "command.square").font(.system(size: 29, weight: .light)).foregroundStyle(Palette.teal)
            }
            VStack(alignment: .leading, spacing: 15) {
                field("操作名（必須・80文字まで）") { TextField("例：サイドバーを切り替える", text: $title).accessibilityIdentifier("editor.title") }
                HStack(alignment: .top, spacing: 16) {
                    field("アプリ名（任意）") { TextField("例：Visual Studio Code", text: $app) }
                    field("カテゴリ") {
                        Picker("カテゴリ", selection: $category) {
                            ForEach(ShortcutCategory.allCases) { category in Text(category.title).tag(category) }
                        }.labelsHidden()
                    }
                }
                VStack(alignment: .leading, spacing: 9) {
                    Text("キーの組み合わせ（必須）").font(.system(size: 11, weight: .medium))
                    HStack(spacing: 8) {
                        ForEach(modifierOrder, id: \.self) { modifier in
                            Toggle(isOn: Binding(get: { modifiers.contains(modifier) }, set: { enabled in
                                if enabled { modifiers.insert(modifier) } else { modifiers.remove(modifier) }
                            })) {
                                Text(modifier).font(.system(size: 20)).frame(width: 29, height: 28)
                            }.toggleStyle(.button).tint(Palette.teal)
                                .help(ShortcutSearch.keyAliases[modifier] ?? modifier)
                        }
                        Text("+").foregroundStyle(Palette.muted)
                        TextField("例：K / Space", text: $key).frame(width: 120).accessibilityIdentifier("editor.key")
                    }
                    Text("修飾キーを選び、最後のキーを文字で入力します。Tab・Return・Delete・矢印も入力できます。")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted)
                }
                if !keys.isEmpty {
                    HStack { Spacer(); KeyCaps(keys: keys); Spacer() }.padding(17)
                        .background(Palette.mint.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
                }
                field("メモ（任意・1,000文字まで）") {
                    TextEditor(text: $note).font(.system(size: 12)).frame(height: 70).scrollContentBackground(.hidden)
                        .padding(5).background(.white, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.line))
                }
            }.textFieldStyle(.roundedBorder)
            Text("早見表への登録です。アプリやmacOSのキー割り当ては変更しません。")
                .font(.system(size: 10)).foregroundStyle(Palette.muted)
            if let saveError { Text(saveError).font(.system(size: 11)).foregroundStyle(.red) }
            HStack {
                Spacer()
                Button("キャンセル") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("保存する") { save() }.buttonStyle(.borderedProminent).tint(Palette.teal)
                    .keyboardShortcut(.defaultAction).disabled(!valid).accessibilityIdentifier("editor.save")
            }
        }.padding(30).frame(width: 555).background(Palette.paper).foregroundStyle(Palette.ink)
    }
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 11, weight: .medium))
            content()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func save() {
        guard valid else { return }
        let item = Shortcut(id: original.id, title: cleanTitle, keys: keys, category: category,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                            customApp: app.trimmingCharacters(in: .whitespacesAndNewlines), isCustom: true)
        if store.save(item) { dismiss() }
        else { saveError = store.errorMessage ?? "保存できませんでした。"; store.errorMessage = nil }
    }
}

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    private let symbols = [("⌘", "Command", "Macの基本操作で使うキー"), ("⌥", "Option", "Altと表記される場合もあります"), ("⇧", "Shift", "大文字や選択範囲の拡張に"), ("⌃", "Control", "Commandとは別のキーです"), ("⇥", "Tab", "項目やアプリの切り替えに"), ("⌫", "Delete", "Macの文字削除キー"), ("⎋", "Escape", "操作のキャンセルに")]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("キー記号のガイド").font(.system(size: 24, weight: .bold))
            Text("修飾キーを押しながら最後のキーを押し、両方を離します。\n例えば ⌘ C は、Commandを押したままCを押します。")
                .font(.system(size: 12)).foregroundStyle(Palette.muted).lineSpacing(5)
            ForEach(symbols, id: \.0) { symbol, name, tip in
                HStack(spacing: 16) {
                    KeyCaps(keys: [symbol])
                    Text(name).font(.system(size: 12, weight: .medium)).frame(width: 78, alignment: .leading)
                    Text(tip).font(.system(size: 11)).foregroundStyle(Palette.muted)
                }
            }
            Divider()
            Text("KeyShelfの操作： ⌘F 検索 / ⌘N 追加 / ↑↓ 一覧を選択\nウインドウを閉じても、メニューバーの⌘アイコンから開けます。")
                .font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(5)
            HStack { Spacer(); Button("閉じる") { dismiss() }.keyboardShortcut(.defaultAction) }
        }.padding(30).frame(width: 510).background(Palette.paper).foregroundStyle(Palette.ink)
    }
}
