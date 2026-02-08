---
title: "ObsidianとText Generatorで、どんなWeb記事でも一瞬で要約する"
source: "https://zenn.dev/jambo_dev/articles/11e009c8ab4fde"
author:
  - "[[Zenn]]"
published: 2026-01-04
created: 2026-01-06
description:
tags:
  - "WebClip"
---
# ✅️ Abstact

- Obsidian、Text Generator、Obsidian Web Clipper、OpenAI(GPT)を使い、Web記事を一瞬で要約する環境を構築する。
- ブラウザからワンクリックで記事をObsidianに保存し、本文を選択して要約を実行する。
- 要約は「タイトル」「3行まとめ」「重要ポイント（技術）」「既存技術との違い」「実務への影響」「次アクション」「関連キーワード」のフォーマットで自動生成される。
-mermaidDiagram
graph TD
    A[Web記事] --> B(Obsidian Web Clipper);
    B --> C(Obsidian);
    C --> D(本文選択);
    D --> E(Text Generator);
    E --> F(OpenAI API);
    F --> G(要約結果);
    G --> C;

- mermaidDiagram
graph TD
    A[Web記事] --> B(Obsidian Web Clipper);
    B --> C(Obsidian);
    C --> D(本文選択);
    D -- テンプレート適用 --> E(Text Generator);
    E -- GPT連携 --> F(OpenAI API);
    F --> G(要約結果);
    G -- ノートに挿入 --> C;

---

# 🗒️ Summary

# ObsidianとText Generatorで、どんなWeb記事でも一瞬で要約する

## この記事を書いた理由

- Obsidianを技術キャッチアップのツールとして活用したい。
- 技術記事の要点を整理し、再利用できる形で残す仕組みを作りたい。

## できるようになること

- ブラウザからワンクリックでWeb記事をObsidianに保存。
- 保存した記事の本文を選択して要約を実行。
- 自動要約フォーマット:
    - # タイトル
    - ## 3行まとめ
    - ## 重要ポイント（技術）
    - ## 既存技術との違い
    - ## 実務への影響
    - ## 次アクション
    - ## 関連キーワード

## 必要なもの

- Obsidian
- Obsidian Web Clipper（ブラウザ拡張）
- Text Generator（コミュニティプラグイン）
- OpenAI API Key
- 要約用テンプレート（mdファイル）

## 全体の仕組み（最小理解）

- Obsidian Web Clipper: Web記事をObsidianに取り込む。
- Text Generator: 選択中のテキストをGPTに渡して要約する。
- GPT（OpenAI API）: 要約文を生成する。
- Text Generatorは指定フォルダ内のmdファイルをテンプレートとして扱う。

## ステップ1：Text Generator プラグインを追加する

- Text Generatorプラグインを追加。

## ステップ2：Text Generator の設定を変更する

### ① OpenAI（GPT）の設定

- OpenAI API Keyを設定。
- Base URL: `https://api.openai.com/v1`
- 使用するモデルは任意。

### ② Templates Path を既存フォルダに設定

- 例: `Tech-Digest/Templates`
- このフォルダにテンプレート用mdファイルを置く。

## ステップ3：要約テンプレートを作る

- `AI_Summarizer.md` を作成。
```markdown
以下は技術記事の本文です。
内容を日本語で技術者向けに要約してください。

出力はMarkdownで、必ず次の見出し構造を使ってください。

# タイトル（推定でOK）
## 3行まとめ
- 
- 
- 

## 重要ポイント（技術）
- 

## 既存技術との違い
- 

## 実務への影響（何が変わるか）
- 

## 次アクション（試す/読む/実装）
- 

## 関連キーワード（5〜10個）

制約:
- 英語でも必ず日本語
- 不明な点は「不明」と書く
- 誇張しない
- 箇条書きは簡潔に

以下が本文です。
---
{{selection}}
```

### ポイント

- `{{selection}}`: 実行時に選択中のテキストが入る変数。
- このテンプレート1つで十分。

## ステップ4：使い方（どんなサイトでも共通）

### 手順

1. ブラウザで記事を開き、Obsidian Web Clipper で保存。
2. Obsidianに保存された記事ノートを開く。
3. 記事本文を選択。
4. コマンドパレット(Command+P)から `Text Generator: Templates:Generate & Insert` を実行。
5. テンプレートとして `AI_Summarizer` を選択。

### 結果

- 要約が開いているノートの末尾に挿入される。
- 見出し構造が揃う。
- 日本語で簡潔にまとまる。

## まとめ

- Obsidian Web Clipper、Text Generator、GPT を活用し、Web記事の要点を構造化して要約することで、知識として蓄積できる。
- どんな技術記事でも同じ手順で扱え、技術キャッチアップを無理なく継続できる。

## 📢 採用情報

- 株式会社ジャンボではエンジニアを募集中。
- Wantedly: [https://www.wantedly.com/companies/company_725162](https://www.wantedly.com/companies/company_725162)
- Recruit: [https://jambo-inc.io/recruit/](https://jambo-inc.io/recruit/)

