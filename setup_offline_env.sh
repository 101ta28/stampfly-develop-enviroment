#!/bin/bash

# StampFly オフライン環境セットアップスクリプト
# このスクリプトは完全オフライン環境でStampFlyの開発環境を構築します

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORMIO_CACHE_ARCHIVE="platformio_cache.tar.gz"
TARGET_PLATFORMIO_DIR="$SCRIPT_DIR/.platformio"

echo "StampFly オフライン環境セットアップを開始します..."

# オフライン環境チェック
check_offline_mode() {
    echo "オフライン環境の確認中..."
    if ping -c 1 google.com >/dev/null 2>&1; then
        echo "警告: インターネット接続が検出されました。完全オフライン環境ではありません。"
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "セットアップを中止しました。"
            exit 1
        fi
    else
        echo "オフライン環境を確認しました。"
    fi
}

# PlatformIOキャッシュアーカイブの存在確認
check_cache_archive() {
    if [ ! -f "$SCRIPT_DIR/$PLATFORMIO_CACHE_ARCHIVE" ]; then
        echo "エラー: $PLATFORMIO_CACHE_ARCHIVE が見つかりません。"
        echo "オンライン環境で以下のコマンドを実行してキャッシュを作成してください:"
        echo "  ./create_offline_cache.sh"
        exit 1
    fi
    echo "PlatformIOキャッシュアーカイブが見つかりました。"
}

# 既存のPlatformIOディレクトリのバックアップ
backup_existing_platformio() {
    if [ -d "$TARGET_PLATFORMIO_DIR" ]; then
        echo "既存の PlatformIO ディレクトリをバックアップしています..."
        mv "$TARGET_PLATFORMIO_DIR" "$TARGET_PLATFORMIO_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# PlatformIOキャッシュの展開
extract_cache() {
    echo "PlatformIOキャッシュを展開しています..."
    cd "$SCRIPT_DIR"
    tar -xzf "$PLATFORMIO_CACHE_ARCHIVE"
    echo "キャッシュの展開が完了しました。"
}

# Python仮想環境のセットアップ
setup_python_env() {
    echo "Python仮想環境をセットアップしています..."
    cd "$SCRIPT_DIR"
    
    # uvが利用可能かチェック
    if ! command -v uv &> /dev/null; then
        echo "エラー: uv コマンドが見つかりません。"
        echo "uvをインストールしてから再実行してください。"
        exit 1
    fi
    
    # PlatformIOホームディレクトリをプロジェクト内に設定
    export PLATFORMIO_CORE_DIR="$TARGET_PLATFORMIO_DIR"
    
    # 仮想環境作成（オフライン）
    if [ -f "requirements.txt" ]; then
        echo "requirements.txtから依存関係をインストールしています..."
        uv sync --offline || uv sync
    else
        echo "requirements.txtが見つかりません。オンライン環境でuv syncを実行します..."
        uv sync
    fi
}

# ビルドテスト
test_build() {
    echo "オフライン環境でのビルドテストを実行しています..."
    cd "$SCRIPT_DIR"
    
    # PlatformIOホームディレクトリを設定
    export PLATFORMIO_CORE_DIR="$TARGET_PLATFORMIO_DIR"
    
    if uvx platformio run --target checkprogsize; then
        echo "✅ ビルドテストが成功しました！"
        echo "完全オフライン環境でのビルドが可能です。"
    else
        echo "❌ ビルドテストが失敗しました。"
        echo "依存関係が不足している可能性があります。"
        exit 1
    fi
}

# 環境情報の表示
show_environment_info() {
    echo ""
    echo "=== オフライン環境セットアップ完了 ==="
    echo "PlatformIO バージョン: $(uvx platformio --version | head -n1)"
    echo "Python 仮想環境: $(uv python --version 2>/dev/null || echo 'N/A')"
    echo "プロジェクトディレクトリ: $SCRIPT_DIR"
    echo ""
    echo "利用可能なコマンド:"
    echo "  ビルド: uvx platformio run"
    echo "  書き込み: uvx platformio run --target upload"
    echo "  サイズ確認: uvx platformio run --target checkprogsize"
    echo ""
}

# メイン実行
main() {
    check_offline_mode
    check_cache_archive
    backup_existing_platformio
    extract_cache
    setup_python_env
    test_build
    show_environment_info
    
    echo "StampFly オフライン環境のセットアップが完了しました！"
}

# スクリプト実行
main "$@"