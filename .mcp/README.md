# Figma MCP 設定指南

本專案已整合 Figma Model Context Protocol (MCP),讓您可以在 VSCode 中直接與 Figma 設計檔案互動。

## 前置需求

- VSCode
- Node.js 和 npm
- Figma 帳號與 Access Token

## 安裝步驟

### 1. 安裝 MCP 伺服器

本專案的 `.vscode/settings.json` 已經設定好兩個 MCP 伺服器:

1. **Filesystem MCP**: 提供檔案系統存取
   - 套件: `@modelcontextprotocol/server-filesystem`
   
2. **Framelink Figma MCP**: 提供 Figma API 整合
   - 套件: `figma-developer-mcp`

### 2. 取得 Figma Access Token

1. 登入 [Figma](https://www.figma.com)
2. 點擊右上角頭像 → **Settings**
3. 在左側選單選擇 **Personal Access Tokens**
4. 點擊 **Generate new token**
5. 輸入 Token 名稱(例如: "VSCode MCP")
6. 複製產生的 Token(只會顯示一次,請妥善保存)

### 3. 設定環境變數

#### 方法一: 使用 .env 檔案(推薦)

1. 複製 `.env.example` 為 `.env`:
   ```bash
   cp .env.example .env
   ```

2. 編輯 `.env` 檔案,填入您的 Figma Access Token:
   ```
   FIGMA_ACCESS_TOKEN=figd_你的實際Token
   ```

3. 確保 `.env` 已加入 `.gitignore`(避免洩漏 Token)

#### 方法二: 設定系統環境變數

**macOS/Linux**:
```bash
export FIGMA_ACCESS_TOKEN="figd_你的實際Token"
```

將上述指令加入 `~/.zshrc` 或 `~/.bashrc` 以永久設定。

**Windows**:
```powershell
setx FIGMA_ACCESS_TOKEN "figd_你的實際Token"
```

### 4. 啟用 MCP 伺服器

1. 重新啟動 VSCode
2. 開啟 VSCode 指令面板:
   - Mac: `Shift + Cmd + P`
   - Windows: `Shift + Ctrl + P`
3. 輸入 `MCP` 並選擇相關指令確認伺服器狀態

### 5. 驗證設定

開啟 VSCode 後,MCP 伺服器會自動啟動。您可以在:
- VSCode 輸出面板查看 MCP 伺服器日誌
- 使用 GitHub Copilot Chat 時,應該能夠存取 Figma 相關功能

## 可用的 Figma MCP 功能

透過 `figma-developer-mcp`,您可以:

- 讀取 Figma 設計檔案資訊
- 取得圖層結構和屬性
- 匯出設計資產
- 查詢設計 Token
- 自動化設計到程式碼的工作流程

## 故障排除

### Token 無效

如果遇到認證錯誤:
1. 確認 `.env` 檔案中的 Token 正確無誤
2. 確認 Token 未過期
3. 重新產生新的 Figma Access Token

### MCP 伺服器無法啟動

1. 確認已安裝 Node.js 和 npm
2. 檢查網路連線
3. 嘗試手動安裝套件:
   ```bash
   npx -y @modelcontextprotocol/server-filesystem
   npx -y figma-developer-mcp
   ```

### 環境變數未載入

1. 確認 `.env` 檔案位於專案根目錄
2. 重新啟動 VSCode
3. 檢查環境變數是否正確設定:
   ```bash
   echo $FIGMA_ACCESS_TOKEN  # macOS/Linux
   echo %FIGMA_ACCESS_TOKEN% # Windows
   ```

## 安全性注意事項

⚠️ **重要**: 
- 絕對不要將 `.env` 檔案或包含 Access Token 的設定提交到版本控制
- `.env` 應該已加入 `.gitignore`
- 定期輪換 Access Token
- 如果 Token 洩漏,立即在 Figma 設定中撤銷並重新產生

## 相關連結

- [Figma API 文件](https://www.figma.com/developers/api)
- [MCP 規範](https://modelcontextprotocol.io/)
- [figma-developer-mcp GitHub](https://github.com/doanthuanthanh88/figma-developer-mcp)

## 支援

如有問題,請參考:
1. 本文件的故障排除章節
2. VSCode MCP 官方文件
3. 專案 Issues 區
