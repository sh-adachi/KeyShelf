import AppKit
import SwiftUI
import KeyShelfCore

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var state = LibraryState()
    @Published var query = ""
    @Published var filter: LibraryFilter = .all
    @Published var selection: String? = "copy"
    @Published var editor: Shortcut?
    @Published var errorMessage: String?
    @Published var copiedID: String?
    @Published var sortByName = false
    private let file: LibraryFile
    private var canSave = true
    private var copyTask: Task<Void, Never>?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KeyShelf", isDirectory: true)
        file = LibraryFile(url: directory.appendingPathComponent("library.json"))
        do { state = try file.load() }
        catch {
            canSave = false
            errorMessage = "保存データを読み込めませんでした。元のファイルを保護するため、この起動中は変更を保存できません。\n\(file.url.path)\n\(error.localizedDescription)"
        }
    }

    var all: [Shortcut] { Catalog.shortcuts + state.customShortcuts }
    var results: [Shortcut] {
        let items = ShortcutSearch.results(in: all, query: query, filter: filter, favorites: state.favorites)
        return sortByName ? items.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending } : items
    }
    var selected: Shortcut? { results.first { $0.id == selection } }
    func count(_ filter: LibraryFilter) -> Int {
        ShortcutSearch.results(in: all, query: "", filter: filter, favorites: state.favorites).count
    }
    func navigate(_ target: LibraryFilter) {
        filter = target
        query = ""
        selection = results.first?.id
    }
    func reconcileSelection() {
        if !results.contains(where: { $0.id == selection }) { selection = results.first?.id }
    }
    @discardableResult
    private func commit(_ next: LibraryState) -> Bool {
        guard canSave else {
            errorMessage = "保存データを読み込めなかったため、変更を保存できません。Application Support/KeyShelf/library.jsonを確認してアプリを起動し直してください。"
            return false
        }
        do { try file.save(next); state = next; return true }
        catch { errorMessage = "変更を保存できませんでした。\n\(error.localizedDescription)"; return false }
    }
    func toggleFavorite(_ item: Shortcut) {
        var next = state
        if next.favorites.contains(item.id) { next.favorites.remove(item.id) }
        else { next.favorites.insert(item.id) }
        _ = commit(next)
    }
    func newShortcut() {
        editor = Shortcut(title: "", keys: ["⌘", ""], category: .basics, isCustom: true)
    }
    func save(_ item: Shortcut) -> Bool {
        var next = state
        do { try next.saveCustom(item) }
        catch { errorMessage = error.localizedDescription; return false }
        guard commit(next) else { return false }
        filter = .custom; query = ""; selection = item.id
        return true
    }
    func delete(_ item: Shortcut) {
        var next = state
        next.deleteCustom(id: item.id)
        if commit(next) { reconcileSelection() }
    }
    func copy(_ item: Shortcut) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(item.title)  \(item.keyLabel)", forType: .string)
        copiedID = item.id
        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copiedID = nil }
        }
    }
}

enum Palette {
    static let ink = Color(red: 0.10, green: 0.18, blue: 0.18)
    static let teal = Color(red: 0.12, green: 0.43, blue: 0.37)
    static let sidebar = Color(red: 0.08, green: 0.20, blue: 0.19)
    static let paper = Color(red: 0.97, green: 0.98, blue: 0.96)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.47)
    static let line = Color(red: 0.87, green: 0.90, blue: 0.87)
    static let mint = Color(red: 0.88, green: 0.94, blue: 0.89)
}

struct KeyCaps: View {
    var keys: [String]
    var large = false
    var body: some View {
        HStack(spacing: large ? 8 : 5) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                Text(key)
                    .font(.system(size: large ? 27 : 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .frame(minWidth: large ? 51 : 29, minHeight: large ? 56 : 30)
                    .padding(.horizontal, key.count > 1 ? 8 : 0)
                    .background(.white, in: RoundedRectangle(cornerRadius: large ? 11 : 6))
                    .overlay(RoundedRectangle(cornerRadius: large ? 11 : 6).stroke(Palette.line, lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 0, y: large ? 3 : 2)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(keys.map { ShortcutSearch.keyAliases[$0]?.components(separatedBy: " ").first ?? $0 }.joined(separator: " + "))
    }
}
