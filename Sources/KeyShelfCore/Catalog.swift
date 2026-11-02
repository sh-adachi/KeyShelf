import Foundation

public enum Catalog {
    public static let shortcuts: [Shortcut] = {
        var items: [Shortcut] = []
        func add(_ category: ShortcutCategory, _ id: String, _ title: String, _ keys: [String], _ note: String = "", _ keywords: String = "") {
            items.append(Shortcut(id: id, title: title, keys: keys, category: category, note: note, keywords: keywords))
        }
        add(.basics, "copy", "コピー", ["⌘", "C"], "選択した内容をクリップボードへ。Finderのファイルにも使えます。", "copy こぴー")
        add(.basics, "paste", "ペースト", ["⌘", "V"], "コピーした内容を、選んだ場所へ貼り付けます。", "paste 貼り付け はりつけ")
        add(.basics, "cut", "カット", ["⌘", "X"], "選択したテキストなどを切り取ります。Finderのファイル移動は ⌥⌘V を使います。", "cut 切り取り")
        add(.basics, "undo", "取り消す", ["⌘", "Z"], "直前の操作を戻します。対応する操作はアプリによって異なります。", "undo 元に戻す")
        add(.basics, "redo", "やり直す", ["⇧", "⌘", "Z"], "取り消した操作をもう一度行います。", "redo")
        add(.basics, "select-all", "すべて選択", ["⌘", "A"], "編集中のテキストや一覧の項目をまとめて選択。", "select all 全選択")
        add(.basics, "find", "検索する", ["⌘", "F"], "書類やページ内の検索を開きます。", "find 検索 けんさく")
        add(.basics, "find-next", "次の検索結果へ", ["⌘", "G"], "検索した語句の次の一致箇所へ移動。", "find next")
        add(.basics, "save", "保存する", ["⌘", "S"], "作業中の書類を保存。", "save セーブ")
        add(.basics, "open", "ファイルを開く", ["⌘", "O"], "選択項目を開くか、ファイル選択画面を表示。", "open")
        add(.basics, "print", "プリント", ["⌘", "P"], "印刷の設定画面を開きます。", "print 印刷")
        add(.basics, "close", "ウインドウを閉じる", ["⌘", "W"], "最前面のウインドウやタブを閉じます。", "close")

        add(.finder, "new-window", "新しいFinderウインドウ", ["⌘", "N"])
        add(.finder, "new-folder", "新しいフォルダ", ["⇧", "⌘", "N"], "表示している場所に空のフォルダを作成。", "folder フォルダー")
        add(.finder, "duplicate", "ファイルを複製", ["⌘", "D"], "選択したファイルのコピーを同じ場所に作成。", "duplicate")
        add(.finder, "info", "情報を見る", ["⌘", "I"], "選択項目の種類、容量、場所などを確認。", "info")
        add(.finder, "quick-look", "クイックルック", ["Space"], "ファイルを選択して押すと、開かずに内容をプレビュー。", "preview プレビュー")
        add(.finder, "go-folder", "フォルダへ移動", ["⇧", "⌘", "G"], "フォルダのパスを入力して移動。", "path パス")
        add(.finder, "downloads", "ダウンロードを開く", ["⌥", "⌘", "L"], "ダウンロードフォルダへ直接移動。", "downloads")
        add(.finder, "desktop", "デスクトップを開く", ["⇧", "⌘", "D"])
        add(.finder, "home", "ホームフォルダを開く", ["⇧", "⌘", "H"])
        add(.finder, "parent", "上の階層へ移動", ["⌘", "↑"], "現在のフォルダを含むフォルダへ移動。")
        add(.finder, "move-files", "コピーしたファイルを移動", ["⌥", "⌘", "V"], "⌘Cでコピーしたファイルを、現在のフォルダへ移動。", "切り取り 移す")
        add(.finder, "trash", "ゴミ箱に入れる", ["⌘", "⌫"], "選択した項目をゴミ箱へ移動します。", "delete 削除 ごみ箱")
        add(.finder, "list-view", "リスト表示にする", ["⌘", "2"], "ファイルをリスト形式で表示。")
        add(.finder, "airdrop", "AirDropを開く", ["⇧", "⌘", "R"], "近くのAppleデバイスとファイルを共有。")

        add(.system, "switch-app", "アプリを切り替える", ["⌘", "⇥"], "⌘を押したままTabで選択し、⌘を離して切り替えます。", "switch app タブ")
        add(.system, "spotlight", "Spotlightを開く", ["⌘", "Space"], "アプリやファイルを検索。入力ソースの設定と競合する場合があります。", "検索 スポットライト")
        add(.system, "hide", "アプリを隠す", ["⌘", "H"], "最前面のアプリのウインドウを一時的に隠します。")
        add(.system, "minimize", "Dockにしまう", ["⌘", "M"], "最前面のウインドウを最小化。", "minimize")
        add(.system, "fullscreen", "フルスクリーンを切り替える", ["⌃", "⌘", "F"], "フルスクリーン対応のアプリで使用できます。")
        add(.system, "lock", "画面をロック", ["⌃", "⌘", "Q"], "席を離れる前に、Macの画面をロック。", "lock ロック")
        add(.system, "mission-control", "Mission Control", ["⌃", "↑"], "開いているウインドウを一覧表示。設定で変更されている場合があります。")
        add(.system, "app-windows", "アプリのウインドウを一覧表示", ["⌃", "↓"], "最前面のアプリで開いているウインドウを確認。")
        add(.system, "emoji", "絵文字と記号", ["⌃", "⌘", "Space"], "文字ビューアから絵文字や記号を入力。", "emoji えもじ")
        add(.system, "dock", "Dockの表示を切り替える", ["⌥", "⌘", "D"])
        add(.system, "quit", "アプリを終了", ["⌘", "Q"], "作業中のアプリを終了します。未保存の内容を確認してください。", "quit")
        add(.system, "force-quit", "強制終了の画面を開く", ["⌥", "⌘", "⎋"], "応答しないアプリを選んで終了。保存していない変更が失われる場合があります。")

        add(.capture, "capture-all", "画面全体を撮影", ["⇧", "⌘", "3"], "画面全体のスクリーンショットを保存。", "screenshot スクショ 撮る")
        add(.capture, "capture-area", "選択した範囲を撮影", ["⇧", "⌘", "4"], "ポインタで範囲をドラッグ。Escでキャンセルできます。", "screenshot スクショ 範囲")
        add(.capture, "capture-tools", "撮影・画面収録ツール", ["⇧", "⌘", "5"], "撮影範囲、画面収録、保存先などを選べます。", "screenshot スクショ 録画 動画")
        add(.capture, "capture-copy", "画面全体をコピー", ["⌃", "⇧", "⌘", "3"], "ファイル保存の代わりにクリップボードへ。⌘Vで貼り付けできます。", "screenshot スクショ")

        add(.text, "line-start", "行の先頭へ", ["⌘", "←"], "カーソルを現在の行の先頭に移動。")
        add(.text, "line-end", "行の末尾へ", ["⌘", "→"], "カーソルを現在の行の末尾に移動。")
        add(.text, "word-left", "前の単語へ", ["⌥", "←"], "単語単位でカーソルを左へ移動。")
        add(.text, "word-right", "次の単語へ", ["⌥", "→"], "単語単位でカーソルを右へ移動。")
        add(.text, "select-line", "行末まで選択", ["⇧", "⌘", "→"], "カーソルから行末までを選択。")
        add(.text, "doc-start", "書類の先頭へ", ["⌘", "↑"])
        add(.text, "doc-end", "書類の末尾へ", ["⌘", "↓"])
        add(.text, "bold", "太字を切り替える", ["⌘", "B"], "書式設定に対応するエディタで使えます。", "bold")
        add(.text, "match-style", "スタイルを合わせてペースト", ["⌥", "⇧", "⌘", "V"], "貼り付け先の書式でペースト。対応はアプリによって異なります。", "書式なし 貼り付け")

        add(.safari, "safari-back", "前のページへ戻る", ["⌘", "["], "表示履歴のひとつ前のページへ。", "back ブラウザ")
        add(.safari, "safari-forward", "次のページへ進む", ["⌘", "]"], "戻る操作の後、次のページへ。", "forward ブラウザ")
        add(.safari, "safari-reopen", "閉じたタブ・ウインドウを開く", ["⇧", "⌘", "T"], "最後に閉じたタブやウインドウを再び開きます。", "復元 reopen")
        add(.safari, "safari-home", "ホームページへ", ["⇧", "⌘", "H"], "Safariで設定したホームページを開きます。")
        add(.safari, "safari-bookmarks", "ブックマークを表示", ["⌃", "⌘", "1"], "ブックマークのサイドバーの表示を切り替え。")
        add(.safari, "safari-settings", "Safariの設定を開く", ["⌘", ","])
        return items
    }()
}
