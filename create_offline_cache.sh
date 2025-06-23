#!/bin/bash

# StampFly オフラインキャッシュ作成スクリプト
# このスクリプトは事前にオンライン環境でPlatformIOキャッシュを作成します

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORMIO_CACHE_ARCHIVE="platformio_cache.tar.gz"
PLATFORMIO_DIR="$SCRIPT_DIR/.platformio"

echo "StampFly オフラインキャッシュ作成を開始します..."

# インターネット接続確認
check_internet_connection() {
    echo "インターネット接続を確認中..."
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        echo "エラー: インターネット接続が必要です。"
        echo "このスクリプトはオンライン環境で実行してください。"
        exit 1
    fi
    echo "インターネット接続を確認しました。"
}

# 依存関係の事前ダウンロード
download_dependencies() {
    echo "Python依存関係をダウンロードしています..."
    cd "$SCRIPT_DIR"
    
    # uvが利用可能かチェック
    if ! command -v uv &> /dev/null; then
        echo "エラー: uv コマンドが見つかりません。"
        echo "uvをインストールしてから再実行してください: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
    
    # Python仮想環境と依存関係のセットアップ
    echo "uv sync を実行しています..."
    uv sync
    
    echo "Python依存関係のキャッシュを作成しています..."
    uv export --format requirements-txt > requirements.txt
    
    # PlatformIOホームディレクトリをプロジェクト内に設定
    export PLATFORMIO_CORE_DIR="$PLATFORMIO_DIR"
    
    echo "PlatformIO依存関係をダウンロードしています..."
    # すべての依存関係を強制的にダウンロード
    uvx platformio platform install espressif32 --force
    uvx platformio lib install --force
    
    # ビルドして全ての依存関係をダウンロード
    echo "ビルドを実行してすべての依存関係をダウンロードしています..."
    uvx platformio run --target checkprogsize
    
    echo "依存関係のダウンロードが完了しました。"
}

# PlatformIOキャッシュサイズ確認
check_cache_size() {
    if [ -d "$PLATFORMIO_DIR" ]; then
        CACHE_SIZE=$(du -sh "$PLATFORMIO_DIR" | cut -f1)
        echo "PlatformIOキャッシュサイズ: $CACHE_SIZE"
    else
        echo "警告: PlatformIOキャッシュディレクトリが見つかりません。"
    fi
}

# キャッシュのアーカイブ作成
create_cache_archive() {
    echo "PlatformIOキャッシュをアーカイブしています..."
    
    if [ ! -d "$PLATFORMIO_DIR" ]; then
        echo "エラー: PlatformIOキャッシュディレクトリが存在しません。"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    tar -czf "$PLATFORMIO_CACHE_ARCHIVE" ".platformio"
    
    echo "キャッシュアーカイブを作成しました: $PLATFORMIO_CACHE_ARCHIVE"
}

# アーカイブ情報の表示
show_archive_info() {
    ARCHIVE_PATH="$SCRIPT_DIR/$PLATFORMIO_CACHE_ARCHIVE"
    if [ -f "$ARCHIVE_PATH" ]; then
        ARCHIVE_SIZE=$(du -sh "$ARCHIVE_PATH" | cut -f1)
        echo ""
        echo "=== アーカイブ作成完了 ==="
        echo "アーカイブファイル: $PLATFORMIO_CACHE_ARCHIVE"
        echo "アーカイブサイズ: $ARCHIVE_SIZE"
        echo "保存場所: $ARCHIVE_PATH"
        echo ""
        echo "オフライン環境での使用方法:"
        echo "1. このアーカイブファイルをオフライン環境にコピー"
        echo "2. ./setup_offline_env.sh を実行"
        echo ""
        echo "含まれる内容:"
        echo "- ESP32開発プラットフォーム"
        echo "- ツールチェーン (GCC, esptool等)"
        echo "- ライブラリ (FastLED, INA3221)"
        echo "- カスタムライブラリ (BMI270, VL53L3C等)"
    fi
}

# メイン実行
main() {
    check_internet_connection
    download_dependencies
    check_cache_size
    create_cache_archive
    show_archive_info
    
    echo "オフラインキャッシュの作成が完了しました！"
}

# スクリプト実行
main "$@"