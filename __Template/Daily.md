---
title: "<タイトルを設定してください>"
date: { { date:YYYY-MM-DD } }
tags:
  - daily
aliases: ["{{date:YYYY年MM月DD日}}"]
---

# {{date:YYYY年MM月DD日}} ({{date:dddd}})

## ✅ 今日の目標

- [ ] 主要タスク 1
- [ ] 主要タスク 2

## 📝 メモ

- 今日の気づきやアイデアを書く

## 📅 スケジュール

- 午前：
- 午後：

## 🔗 関連リンク

-

## ✅ 振り返り

- 良かったこと：
- 改善点：

<%*
async function main() {
    const filename = tp.file.title;   // ex. 2025-12-06
    const [year, month, day] = filename.split("-");

    const folderPath = `MyWork/Daily/${year}/${month}`;
    const filePath   = `${folderPath}/${day}`;

    // フォルダが存在しない場合は作成
    if (!(await app.vault.adapter.exists(folderPath))) {
        await app.vault.createFolder(folderPath);
    }

    // ファイルが既に存在する場合
    if (await app.vault.adapter.exists(filePath)) {
        // 既存ファイルがある → 新規作成された方を削除
        const newFile = app.workspace.getActiveFile();
        if (newFile && newFile.path !== filePath) {
            await app.vault.trash(newFile, true);
            new Notice(`既存ファイルを尊重し、新規作成分を削除しました: ${newFile.path}`);
        } else {
            new Notice(`既存ファイルがあるため移動をスキップしました: ${filePath}`);
        }
    } else {
        // 既存ファイルがない場合は通常通り移動
        await tp.file.move(filePath);
        new Notice(`ファイルを移動しました: ${filePath}`);
    }
}
main();
%>

