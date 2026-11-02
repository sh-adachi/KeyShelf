import Foundation

public enum ShortcutCategory: String, Codable, CaseIterable, Identifiable {
    case basics, finder, system, capture, text, safari
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .basics: return "基本操作"
        case .finder: return "Finder"
        case .system: return "ウインドウとシステム"
        case .capture: return "スクリーンショット"
        case .text: return "テキスト編集"
        case .safari: return "Safari"
        }
    }
    public var symbol: String {
        switch self {
        case .basics: return "command"
        case .finder: return "folder"
        case .system: return "macwindow.on.rectangle"
        case .capture: return "viewfinder"
        case .text: return "text.cursor"
        case .safari: return "safari"
        }
    }
    public var scope: String {
        switch self {
        case .basics: return "対応アプリ共通"
        case .finder: return "Finder"
        case .system, .capture: return "macOS"
        case .text: return "対応するテキストエディタ"
        case .safari: return "Safari"
        }
    }
}

public struct Shortcut: Codable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var keys: [String]
    public var category: ShortcutCategory
    public var note: String
    public var keywords: String
    public var customApp: String?
    public var isCustom: Bool
    public var scope: String { customApp.flatMap { $0.isEmpty ? nil : $0 } ?? category.scope }
    public var keyLabel: String { keys.joined(separator: " ") }
    public var sourceURL: URL? {
        guard !isCustom else { return nil }
        return URL(string: category == .safari
            ? "https://support.apple.com/ja-jp/guide/safari/cpsh003/mac"
            : "https://support.apple.com/ja-jp/102650")
    }

    public init(id: String = UUID().uuidString, title: String, keys: [String], category: ShortcutCategory,
                note: String = "", keywords: String = "", customApp: String? = nil, isCustom: Bool = false) {
        self.id = id; self.title = title; self.keys = keys; self.category = category
        self.note = note; self.keywords = keywords; self.customApp = customApp; self.isCustom = isCustom
    }
}

public enum LibraryFilter: Equatable {
    case all, favorites, custom, category(ShortcutCategory)
    public var title: String {
        switch self {
        case .all: return "すべてのショートカット"
        case .favorites: return "お気に入り"
        case .custom: return "マイショートカット"
        case .category(let category): return category.title
        }
    }
}

public enum ShortcutSearch {
    public static func normalize(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        return folded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? folded
    }

    public static func results(in shortcuts: [Shortcut], query: String, filter: LibraryFilter,
                               favorites: Set<String>) -> [Shortcut] {
        var normalizedQuery = normalize(query)
        for symbol in ["⌘", "⌥", "⇧", "⌃"] {
            normalizedQuery = normalizedQuery.replacingOccurrences(of: symbol, with: " \(symbol) ")
        }
        let tokens = normalizedQuery.split(whereSeparator: { $0.isWhitespace || $0 == "+" }).map(String.init)
        return shortcuts.filter { item in
            switch filter {
            case .all: break
            case .favorites: guard favorites.contains(item.id) else { return false }
            case .custom: guard item.isCustom else { return false }
            case .category(let category): guard item.category == category else { return false }
            }
            var keyWords = item.keyLabel
            for key in item.keys {
                keyWords += " " + (keyAliases[key] ?? key)
            }
            let haystack = normalize([item.title, item.note, item.keywords, item.scope, item.category.title, keyWords].joined(separator: " "))
            return tokens.allSatisfy { token in
                if let symbol = modifierTokens[token] { return item.keys.contains(symbol) }
                if token.count == 1, let scalar = token.unicodeScalars.first,
                   CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains(scalar) {
                    return item.keys.contains { normalize($0) == token }
                }
                return haystack.contains(token)
            }
        }
    }

    public static let keyAliases = [
        "⌘": "command cmd コマンド", "⌥": "option alt オプション", "⇧": "shift シフト",
        "⌃": "control ctrl コントロール", "Space": "space スペース", "⇥": "tab タブ",
        "⌫": "delete backspace デリート", "⎋": "escape esc エスケープ", "⏎": "return enter リターン",
        "←": "left 左", "→": "right 右", "↑": "up 上", "↓": "down 下"
    ]
    private static let modifierTokens = [
        "cmd": "⌘", "command": "⌘", "⌘": "⌘", "コマンド": "⌘",
        "option": "⌥", "alt": "⌥", "⌥": "⌥", "オプション": "⌥",
        "shift": "⇧", "⇧": "⇧", "シフト": "⇧",
        "control": "⌃", "ctrl": "⌃", "⌃": "⌃", "コントロール": "⌃"
    ]
}

public struct LibraryState: Codable, Equatable {
    public var favorites: Set<String>
    public var customShortcuts: [Shortcut]
    public init(favorites: Set<String> = [], customShortcuts: [Shortcut] = []) {
        self.favorites = favorites; self.customShortcuts = customShortcuts
    }

    public mutating func saveCustom(_ shortcut: Shortcut) throws {
        guard shortcut.isCustom,
              !shortcut.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !shortcut.keys.isEmpty,
              shortcut.keys.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              !Catalog.shortcuts.contains(where: { $0.id == shortcut.id }) else { throw LibraryError.invalidShortcut }
        if let index = customShortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            customShortcuts[index] = shortcut
        } else { customShortcuts.append(shortcut) }
    }

    public mutating func deleteCustom(id: String) {
        guard customShortcuts.contains(where: { $0.id == id }) else { return }
        customShortcuts.removeAll { $0.id == id }
        favorites.remove(id)
    }
}

public enum LibraryError: LocalizedError {
    case invalidShortcut
    public var errorDescription: String? { "ショートカットの名前とキーを確認してください。" }
}

public struct LibraryFile {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> LibraryState {
        guard FileManager.default.fileExists(atPath: url.path) else { return LibraryState() }
        return try JSONDecoder().decode(LibraryState.self, from: Data(contentsOf: url))
    }
    public func save(_ state: LibraryState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: url, options: .atomic)
    }
}
