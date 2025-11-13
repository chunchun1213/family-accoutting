#!/bin/bash
# Figma MCP 快速設定腳本
# 使用方式: ./setup-figma-mcp.sh

set -e

echo "🚀 開始設定 Figma MCP..."
echo ""

# 檢查 Node.js 是否已安裝
if ! command -v node &> /dev/null; then
    echo "❌ 錯誤: 未安裝 Node.js"
    echo "請先安裝 Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js 版本: $(node --version)"
echo ""

# 檢查 .env 檔案
if [ ! -f .env ]; then
    echo "📝 建立 .env 檔案..."
    cp .env.example .env
    echo "⚠️  請編輯 .env 檔案並填入您的 Figma Access Token"
    echo ""
    echo "取得 Figma Token 的步驟:"
    echo "1. 登入 Figma (https://www.figma.com)"
    echo "2. 前往 Settings > Personal Access Tokens"
    echo "3. 產生新的 Token 並複製"
    echo "4. 編輯 .env 檔案,填入 Token"
    echo ""
    
    # 在 macOS 上自動開啟編輯器
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -p "是否現在開啟 .env 檔案進行編輯? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open -e .env
        fi
    fi
else
    echo "✅ .env 檔案已存在"
    
    # 檢查是否已設定 Token
    if grep -q "your_figma_access_token_here" .env; then
        echo "⚠️  警告: .env 檔案中尚未設定實際的 Figma Token"
        echo "請編輯 .env 檔案並填入您的 Token"
    else
        echo "✅ Figma Token 已設定"
    fi
fi

echo ""
echo "📦 預先安裝 MCP 套件..."

# 安裝 Filesystem MCP
echo "正在安裝 @modelcontextprotocol/server-filesystem..."
npx -y @modelcontextprotocol/server-filesystem --version > /dev/null 2>&1 || true

# 安裝 Figma Developer MCP
echo "正在安裝 figma-developer-mcp..."
npx -y figma-developer-mcp --version > /dev/null 2>&1 || true

echo ""
echo "✅ MCP 套件安裝完成"
echo ""
echo "🎉 設定完成!"
echo ""
echo "下一步:"
echo "1. 確認 .env 檔案中的 Figma Token 已正確設定"
echo "2. 重新啟動 VSCode"
echo "3. 開啟 VSCode 指令面板 (Shift + Cmd + P)"
echo "4. 輸入 'MCP' 確認伺服器狀態"
echo ""
echo "詳細說明請參考: .mcp/README.md"
