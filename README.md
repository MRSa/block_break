# Block Break (ブロック崩し)

Flutter で実装したブロック崩しゲーム。

## 遊び方

- 起動直後にタイトル画面（「ブロック崩し」）が表示される
- 「開始: 」のドロップダウンで開始レベル（1〜12）を選択し、『スタート』ボタンを押すとゲーム画面へ遷移
  - 開始レベルは `shared_preferences` に保存され、アプリ再起動後も保持されます
- ゲーム画面で「発射」ボタン（またはタップ/SPACE）を押すとボールが発射されゲーム開始
- パドルはマウス/タッチ（ドラッグ・移動）または ←/→/A/D（水平）、↑/↓/W/S（垂直）で 2D に移動
  - パドルの上下移動範囲は画面下 1/3 の領域
- ボールを落とさないようにブロックを全て壊すとレベルクリア
- 耐久値 2・3 のブロックは複数回ヒットが必要
- ヒットで +10、ブロック破壊で +50。ボール落下でライフ減少、ライフ 0 でゲームオーバー
- レベルごとのハイスコアは自動記録され、HUD の「BEST」に表示されます

## 事前準備

- [Flutter SDK](https://flutter.dev/docs/get-started/install)（3.x 以降）
- 各プラットフォームのツールチェーン
  - **Windows**: Visual Studio 2022（「Desktop development with C++」ワークロード）+ Windows 10 SDK
  - **Android**: Android Studio（または Android SDK / Command line tools）
  - **Web**: Chrome など Web ブラウザ

```bash
flutter doctor        # 環境確認
```

## 実行（開発）

```bash
flutter run                          # 接続中のデバイス（任意）にデバッグ実行
flutter run -d windows               # Windows
flutter run -d chrome                # Web (Chrome)
flutter run -d <android-device-id>   # Android（実機またはエミュレータ）
```

> Android 実機を使う場合、端末で「開発者向けオプション → USB デバッグ」を有効にし、
> `flutter devices` に表示されたデバイス ID を指定します。

## ビルド

```bash
flutter build web       # Web   → build/web/
flutter build windows   # Windows → build/windows/x64/runner/Release/block_break.exe
flutter build apk       # Android (汎用 APK) → build/app/outputs/flutter-apk/app-release.apk
flutter build apk --split-per-abi   # ABI 別 APK (arm64 / armv7 / x86_64)
flutter build appbundle  # Android AAB (Play 向け) → build/app/outputs/bundle/release/app-release.aab
```

## インストール方法

### Android へのインストール

1. **APK を生成する**

   ```bash
   flutter build apk --release
   ```

   成果物: `build/app/outputs/flutter-apk/app-release.apk`

   > ABI 別（端末の CPU アーキテクチャのみを含めることで小型化）:
   > ```bash
   > flutter build apk --release --split-per-abi
   > ```
   > 成果物: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` など

2. **APK を端末に転送する**
   - 方法 A（ファイル転送）: USB / メール / ダウンロード等で `app-release.apk` を端末のストレージへコピー
   - 方法 B（adb で直接インストール）:
     ```bash
     adb install -r build/app/outputs/flutter-apk/app-release.apk
     ```
     （`-r` は上書きインストール。初回は不要でも可）

3. **端末で APK を実行する**
   - ファイルアプリから `app-release.apk` をタップ
   - Android 8 以降は「不明な来源のアプリをインストールする許可」の画面が出るため、
     そのアプリ（例: Chrome やファイルアプリ）で許可を有効にする
   - 「インストール」をタップし、完了後「開く」で起動

4. **開発中のみ: USB 経由で直接実行**

   ```bash
   flutter run -d <android-device-id>
   ```

   - 初回は debug ビルドがインストールされ、アプリを自動起動します
   - `flutter run` は端末が解放されるまで `Ctrl+C` で停止（アプリは残ります）

> **補足**
> - 本プロジェクトの `applicationId` は `jp.osdn.gokigen.block_break`（`android/app/build.gradle.kts`）。
>   同名アプリと競合する場合はここで変更してください。
> - `flutter build apk` の release ビルドはデフォルトで **debug キー** で署名されます
>   （`signingConfig = signingConfigs.getByName("debug")`）。Play 配信前に
>   release 用の署名キーを設定してください。
> - エミュレータを使う場合は `flutter emulators` で作成し、`flutter devices` に表示された ID を指定します。
> - `shared_preferences` は端末のローカル（Android は SharedPreferences）に保存されるため、
>   開始レベル・ハイスコアはアプリアンインストール時のみ消去されます。

### Windows へのインストール

**方法 A: EXE を直接実行（推奨・手軽）**
1. `flutter build windows --release`
2. `build/windows/x64/runner/Release/` 内の `block_break.exe` をダブルクリック
   （任意でショートカット作成、または他の PC にこのフォルダごとコピーして持ち込み）

**方法 B: インストーラ（MSI / インストーラ EXE）を作成**
- [WiX Toolset](https://wixtoolset.org/) を導入し、`build/windows/x64/runner/Release/` をパッケージ化
- または [Inno Setup](https://jrsoftware.org/isinfo.php) で自作インストーラを作成
- 成果物を他 PC にコピーして実行し、Windows の UAC の承認で「インストール」相当

### Web の「インストール」

- `flutter build web` により `build/web/` が生成される
- 任意の静的ホスティング（GitHub Pages / Netlify / Firebase Hosting / Nginx など）で
  `build/web/` の中身を公開
- ブラウザで URL を開けばプレイ可能（PWA 化は別途 `flutter pub add flutter_web_plugins` 等で対応）

## 構成

- `lib/game/entities.dart` — パドル・ボール・ブロックのモデル
- `lib/game/collision.dart` — 衝突判定（円-矩形、壁、パドル反射角）
- `lib/game/game_state.dart` — 固定タイムステップのゲームループ・状態管理・12段階レベルパターン
- `lib/ui/game_canvas.dart` — `blockColor` などの共有定義（ゲーム要素描画は標準ウィジェット）
- `lib/ui/game_screen.dart` — 入力処理・HUD・オーバーレイ・ゲーム要素描画・ハイスコア記録
- `lib/ui/title_screen.dart` — タイトル画面（レベル選択 + スタートボタン、shared_preferences で永続化）
- `images/bb_icon.png` — アプリ icon の元画像（Windows / Web / Android に展開）

## テスト

```bash
flutter test
```

- 衝突判定のユニットテスト（17件）
- Widget テスト（タイトル画面表示 + スタートボタン遷移 + 発射ボタン表示・発射）

## 機能一覧（v1.2）

| 機能 | 説明 |
|---|---|
| タイトル画面 | 「ブロック崩し」+ レベル選択 + スタートボタン |
| 開始レベル | 1〜12 を選択可能（shared_preferences で永続化） |
| パドル 2D 移動 | マウス/タッチ + 矢印/WASD。上下は画面下 1/3 範囲 |
| 発射トリガ | 画面中央の「発射」ボタン / タップ / SPACE |
| ハイスコア | レベルごとに記録し、HUD の BEST に表示 |
| 12段階レベル | レベル 6〜12 は新規パターン |
| パドル幅（難易度） | L1-4: 120px / L5-8: 100px / L9-12: 80px |
