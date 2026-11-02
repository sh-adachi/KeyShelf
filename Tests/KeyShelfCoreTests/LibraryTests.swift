import XCTest
@testable import KeyShelfCore

final class LibraryTests: XCTestCase {
    func testCatalogHasUniqueIDsAndEveryCategory() {
        XCTAssertEqual(Catalog.shortcuts.count, Set(Catalog.shortcuts.map(\.id)).count)
        XCTAssertEqual(Set(Catalog.shortcuts.map(\.category)), Set(ShortcutCategory.allCases))
        XCTAssertTrue(Catalog.shortcuts.allSatisfy { !$0.title.isEmpty && !$0.keys.isEmpty && !$0.isCustom && $0.sourceURL != nil })
    }

    func testSearchMatchesJapaneseAliasesWidthCaseAndAllTokens() {
        func ids(_ query: String) -> Set<String> {
            Set(ShortcutSearch.results(in: Catalog.shortcuts, query: query, filter: .all, favorites: []).map(\.id))
        }
        XCTAssertTrue(ids("こぴー").contains("copy"))
        XCTAssertTrue(ids("ＣＭＤ + Ｃ").contains("copy"))
        XCTAssertEqual(ids("cmd c"), ["copy"])
        XCTAssertEqual(ids("shift cmd 4"), ["capture-area"])
        XCTAssertEqual(ids("⇧⌘4"), ["capture-area"])
        XCTAssertEqual(ids("⌘C"), ["copy"])
        XCTAssertFalse(ids("ctrl").contains("copy"))
        XCTAssertTrue(ids("スクショ 範囲").contains("capture-area"))
        XCTAssertTrue(ids("finder option 移動").contains("move-files"))
        XCTAssertTrue(ids("存在しない操作").isEmpty)
        XCTAssertFalse(ids("Safari コピー").contains("copy"))
    }

    func testFavoritesAndCategoryFiltersComposeWithQuery() {
        let favorites: Set<String> = ["copy", "capture-area"]
        let results = ShortcutSearch.results(in: Catalog.shortcuts, query: "スクショ", filter: .favorites, favorites: favorites)
        XCTAssertEqual(results.map(\.id), ["capture-area"])
        let finder = ShortcutSearch.results(in: Catalog.shortcuts, query: "", filter: .category(.finder), favorites: favorites)
        XCTAssertTrue(finder.allSatisfy { $0.category == .finder })
        XCTAssertFalse(finder.isEmpty)
    }

    func testCustomEditDeleteAndFavoritesSurviveDiskRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = LibraryFile(url: dir.appendingPathComponent("nested/library.json"))
        XCTAssertEqual(try file.load(), LibraryState())
        var state = LibraryState(favorites: ["copy"])
        var item = Shortcut(id: "test-custom", title: "サイドバー切替", keys: ["⌘", "B"], category: .basics, customApp: "VS Code", isCustom: true)
        try state.saveCustom(item)
        state.favorites.insert(item.id)
        try file.save(state)
        state = try file.load()
        XCTAssertEqual(state.customShortcuts, [item])
        XCTAssertEqual(state.favorites, ["copy", item.id])
        XCTAssertEqual(ShortcutSearch.results(in: state.customShortcuts, query: "vs code", filter: .custom, favorites: state.favorites), [item])
        item.keys = ["⌘", "J"]
        try state.saveCustom(item)
        XCTAssertEqual(state.customShortcuts.count, 1)
        XCTAssertEqual(state.customShortcuts[0].keys, ["⌘", "J"])
        state.deleteCustom(id: item.id)
        try file.save(state)
        XCTAssertEqual(try file.load().customShortcuts, [])
        XCTAssertEqual(try file.load().favorites, ["copy"])
    }

    func testInvalidCustomEntriesCannotReplaceBuiltins() {
        var state = LibraryState()
        XCTAssertThrowsError(try state.saveCustom(Shortcut(id: "copy", title: "Override", keys: ["X"], category: .basics, isCustom: true)))
        XCTAssertThrowsError(try state.saveCustom(Shortcut(title: "  ", keys: ["X"], category: .basics, isCustom: true)))
        XCTAssertThrowsError(try state.saveCustom(Shortcut(title: "Test", keys: [""], category: .basics, isCustom: true)))
        XCTAssertTrue(state.customShortcuts.isEmpty)
    }

    func testCorruptFileReportsErrorWithoutOverwriting() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = LibraryFile(url: dir.appendingPathComponent("library.json"))
        let data = Data("broken-json".utf8)
        try data.write(to: file.url)
        XCTAssertThrowsError(try file.load())
        XCTAssertEqual(try Data(contentsOf: file.url), data)
    }
}
