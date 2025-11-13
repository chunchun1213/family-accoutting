# Family Accounting

家庭記帳應用程式專案

## 專案結構

```
├── .github/prompts/      # Speckit 指令提示
├── .mcp/                 # MCP 設定與說明文件
├── .specify/             # 專案規格與模板
├── .vscode/              # VSCode 設定
└── design-assets/        # 設計資產
```

## 快速開始

### 1. Figma MCP 設定

本專案整合了 Figma Model Context Protocol,讓您可以在 VSCode 中直接與 Figma 設計檔案互動。

詳細設定步驟請參考: [.mcp/README.md](.mcp/README.md)

快速設定:
```bash
# 1. 複製環境變數範本
cp .env.example .env

# 2. 編輯 .env,填入您的 Figma Access Token
# FIGMA_ACCESS_TOKEN=figd_your_token_here

# 3. 重新啟動 VSCode
```

### 2. 專案憲章

本專案遵循嚴格的開發憲章,定義了程式碼品質、測試標準、使用者體驗一致性和效能要求。

查看完整憲章: [.specify/memory/constitution.md](.specify/memory/constitution.md)

核心原則:
- ✅ 程式碼品質優先
- ✅ 測試驅動開發(TDD)
- ✅ 使用者體驗一致性
- ✅ 效能設計導向
- ✅ 繁體中文文件標準

### 3. 開發工作流程

使用 Speckit 指令進行功能開發:

```bash
# 建立功能規格
/speckit.specify "功能描述"

# 建立實作計畫
/speckit.plan

# 產生任務清單
/speckit.tasks

# 開始實作
/speckit.implement
```

## 相關文件

- [MCP 設定指南](.mcp/README.md)
- [專案憲章](.specify/memory/constitution.md)
- [Agent 指引](AGENTS.md)

## 技術堆疊

- **開發環境**: VSCode + GitHub Copilot
- **設計工具**: Figma + MCP 整合
- **專案管理**: Speckit 工作流程
- **文件語言**: 繁體中文(zh-TW)

## 授權

待定

