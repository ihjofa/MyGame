# Unity Test Framework - CLI実行ガイド

Unity Test Frameworkのテストをコマンドラインから実行し、ファイル変更を自動検出してテストを実行する方法を説明します。

## 目次

1. [概要](#概要)
2. [セットアップ](#セットアップ)
3. [使い方](#使い方)
4. [スクリプトリファレンス](#スクリプトリファレンス)
5. [トラブルシューティング](#トラブルシューティング)

---

## 概要

このプロジェクトには、Unity Test Frameworkのテストを効率的に実行するための以下のスクリプトが用意されています：

| スクリプト | 説明 |
|-----------|------|
| `check-dependencies.sh` | 必要な依存関係を確認 |
| `find-unity.sh` | Unity実行ファイルを自動検出 |
| `run-unity-tests.sh` | Unity TestをCLIから実行 |
| `parse-test-results.sh` | XML結果を解析して表示 |
| `watch-and-test.sh` | ファイル変更を監視して自動テスト実行 |

### 主な機能

- ✅ Unity実行ファイルの自動検出
- ✅ PlayMode/EditModeテストの実行
- ✅ カラー付き結果表示（成功=緑、失敗=赤）
- ✅ テスト結果サマリー（Pass/Fail件数）
- ✅ 失敗時の詳細表示（エラーメッセージ、スタックトレース）
- ✅ ファイル変更の自動検出（inotifywait）
- ✅ デバウンス機能（連続変更を1回にまとめる）

---

## セットアップ

### 1. 依存関係の確認

まず、必要な依存関係がインストールされているか確認します：

```bash
./scripts/check-dependencies.sh
```

**出力例：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Dependency Checker
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking Bash version... ✓ 5.1.16
Checking inotify-tools (for file watching)... ✓ Found
Checking Unity... ✓ Found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ All dependencies are satisfied!
```

### 2. 不足している依存関係のインストール

**inotify-tools（ファイル監視用）:**
```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install inotify-tools

# RHEL/CentOS/Fedora
sudo yum install inotify-tools
```

**Unity Editor:**
- UnityHubからインストール: https://unity.com/download
- または環境変数 `UNITY_PATH` を設定：
  ```bash
  export UNITY_PATH="/path/to/Unity/Editor/Unity"
  ```

---

## 使い方

### 基本的なテスト実行

#### 1. すべてのテストを実行

```bash
./scripts/run-unity-tests.sh
```

PlayModeテストとEditModeテストの両方が実行されます。

**出力例：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Running playmode Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unity Path:      /path/to/Unity/Editor/Unity
Project Path:    /path/to/unity/My project
Test Mode:       playmode
Results File:    test-results/playmode-results-20250120_153045.xml
Log File:        test-results/playmode-log-20250120_153045.txt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Test Results Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total Tests:    7
  ✓ Passed:       7
  ✗ Failed:       0

  Success Rate: 100.0%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 2. PlayModeテストのみ実行

```bash
./scripts/run-unity-tests.sh -m playmode
```

#### 3. EditModeテストのみ実行

```bash
./scripts/run-unity-tests.sh -m editmode
```

#### 4. タイムアウトを設定

```bash
# 1時間（3600秒）のタイムアウト
./scripts/run-unity-tests.sh -t 3600
```

#### 5. 詳細ログを有効化

```bash
./scripts/run-unity-tests.sh -v
```

### ファイル変更の自動検出

ファイル変更を監視して、変更があったときに自動的にテストを実行します。

#### 1. 基本的な使い方（PlayModeテストを監視）

```bash
./scripts/watch-and-test.sh
```

**実行すると：**
- `unity/My project/Assets/` 内の `.cs` および `.inputactions` ファイルを監視
- ファイル変更を検出すると3秒待機（デバウンス）
- 自動的にPlayModeテストを実行
- テスト完了後、再び監視を継続

**出力例：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  File Watcher Started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Watch Directory:  /path/to/unity/My project/Assets
Test Mode:        playmode
Debounce Time:    3s
File Patterns:    *.cs, *.inputactions

Watching for changes... (Press Ctrl+C to stop)

Change detected: Assets/Scripts/PlayerMovement2D.cs (MODIFY)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Change detected - Running tests...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[テスト実行結果が表示される]

Watching for changes...
```

#### 2. 両方のテストモードで監視

```bash
./scripts/watch-and-test.sh -m both
```

#### 3. デバウンス時間を変更（5秒）

```bash
./scripts/watch-and-test.sh -w 5
```

#### 4. カスタムディレクトリを監視

```bash
./scripts/watch-and-test.sh -d "unity/My project/Assets/Scripts"
```

---

## スクリプトリファレンス

### check-dependencies.sh

依存関係をチェックし、インストール状況を表示します。

```bash
./scripts/check-dependencies.sh
```

**チェック項目：**
- Bash バージョン
- inotify-tools（inotifywait）
- Unity Editor
- プロジェクト構造（Unity project, Tests directory）

---

### find-unity.sh

Unity実行ファイルのパスを自動検出します。

```bash
# Unityのパスを取得
./scripts/find-unity.sh

# バージョン情報も表示
./scripts/find-unity.sh --version
```

**検出方法：**
1. PATH環境変数から検索
2. UnityHub管理下のエディタを検索（`~/.local/share/UnityHub/Editor/`）
3. 一般的なインストールパスを検索（`/opt/Unity/`, `/usr/bin/`）
4. システム全体を検索

---

### run-unity-tests.sh

Unity Test FrameworkのテストをCLIから実行します。

```bash
./scripts/run-unity-tests.sh [OPTIONS]
```

**オプション：**

| オプション | 説明 | デフォルト |
|----------|------|-----------|
| `-m, --mode <mode>` | テストモード: `playmode`, `editmode`, `both` | `both` |
| `-t, --timeout <seconds>` | タイムアウト（秒） | `1800` (30分) |
| `-v, --verbose` | 詳細ログを有効化 | 無効 |
| `-h, --help` | ヘルプを表示 | - |

**使用例：**
```bash
# すべてのテストを実行
./scripts/run-unity-tests.sh

# PlayModeのみ実行
./scripts/run-unity-tests.sh -m playmode

# 1時間のタイムアウトで実行
./scripts/run-unity-tests.sh -t 3600

# 詳細ログ付きで実行
./scripts/run-unity-tests.sh -v
```

**結果ファイル：**
- XML結果: `test-results/<mode>-results-<timestamp>.xml`
- ログファイル: `test-results/<mode>-log-<timestamp>.txt`

---

### parse-test-results.sh

NUnit XML形式のテスト結果を解析して表示します。

```bash
./scripts/parse-test-results.sh <test-results.xml>
```

**表示内容：**
- テスト結果サマリー（Total, Passed, Failed, Skipped）
- 成功率（%）
- 失敗したテストの詳細（テスト名、エラーメッセージ、スタックトレース）

**使用例：**
```bash
./scripts/parse-test-results.sh test-results/playmode-results-20250120_153045.xml
```

---

### watch-and-test.sh

ファイル変更を監視して自動的にテストを実行します。

```bash
./scripts/watch-and-test.sh [OPTIONS]
```

**オプション：**

| オプション | 説明 | デフォルト |
|----------|------|-----------|
| `-d, --dir <directory>` | 監視ディレクトリ | `Assets/` |
| `-m, --mode <mode>` | テストモード: `playmode`, `editmode`, `both` | `playmode` |
| `-w, --wait <seconds>` | デバウンス待機時間（秒） | `3` |
| `-h, --help` | ヘルプを表示 | - |

**使用例：**
```bash
# PlayModeテストを監視
./scripts/watch-and-test.sh

# すべてのテストを監視
./scripts/watch-and-test.sh -m both

# デバウンス時間を5秒に設定
./scripts/watch-and-test.sh -w 5

# Scripts/ディレクトリのみ監視
./scripts/watch-and-test.sh -d "unity/My project/Assets/Scripts"
```

**停止方法：**
`Ctrl+C` を押す

---

## トラブルシューティング

### 1. Unity が見つからない

**エラー:**
```
ERROR: Unity not found
```

**解決方法:**
- UnityHub経由でUnityをインストール
- または環境変数 `UNITY_PATH` を設定：
  ```bash
  export UNITY_PATH="/path/to/Unity/Editor/Unity"
  ./scripts/run-unity-tests.sh
  ```

### 2. inotifywait が見つからない

**エラー:**
```
ERROR: inotifywait not found
```

**解決方法:**
```bash
# Debian/Ubuntu
sudo apt-get install inotify-tools

# RHEL/CentOS
sudo yum install inotify-tools
```

### 3. テストがタイムアウトする

**エラー:**
```
✗ Test execution timed out after 1800s
```

**解決方法:**
タイムアウト時間を延長：
```bash
./scripts/run-unity-tests.sh -t 3600  # 1時間
```

### 4. テスト結果ファイルが作成されない

**症状:**
```
ERROR: Test results file not created
```

**原因:**
- Unityプロジェクトのコンパイルエラー
- テストアセンブリが見つからない

**解決方法:**
1. ログファイルを確認：
   ```bash
   cat test-results/playmode-log-*.txt
   ```
2. Unity Editorで開いて手動でコンパイル確認
3. Assembly Definitionファイルが正しく設定されているか確認

### 5. WSL2でファイル監視が動作しない

**症状:**
WSL2環境でinotifywaitがWindowsファイルシステム（/mnt/c/など）の変更を検出しない

**解決方法:**
プロジェクトをWSLのネイティブファイルシステム（`~/`配下）に移動：
```bash
cp -r /mnt/d/unity_projects/MyGame ~/MyGame
cd ~/MyGame
./scripts/watch-and-test.sh
```

### 6. 複数のUnityバージョンがある場合

**症状:**
間違ったバージョンのUnityが検出される

**解決方法:**
環境変数で明示的に指定：
```bash
export UNITY_PATH="/path/to/specific/Unity/Editor/Unity"
./scripts/run-unity-tests.sh
```

---

## CI/CD統合

### GitHub Actions

`.github/workflows/unity-tests.yml`:

```yaml
name: Unity Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Cache Unity Library
        uses: actions/cache@v3
        with:
          path: unity/My project/Library
          key: Library-${{ hashFiles('unity/My project/Assets/**') }}

      - name: Install Unity
        uses: game-ci/unity-builder@v3
        with:
          targetPlatform: StandaloneLinux64

      - name: Run Tests
        run: ./scripts/run-unity-tests.sh

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

---

## 参考資料

- [Unity Test Framework Documentation](https://docs.unity3d.com/Packages/com.unity.test-framework@latest)
- [Unity Command Line Arguments](https://docs.unity3d.com/Manual/CommandLineArguments.html)
- [inotify-tools Documentation](https://github.com/inotify-tools/inotify-tools/wiki)

---

## ライセンス

このプロジェクトのスクリプトはMITライセンスの下で提供されています。
