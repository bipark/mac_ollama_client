<div align='center'>


# ✨ LLM-K - マルチLLMクライアント ✨

_Ollama、LM Studio、Claude、OpenAIをサポートするマルチプラットフォームMacクライアント_

[ENGLISH](README.md) •
[한국어](README_KR.md) •
[中文](README_CH.md)

</div>

# LLM-K

LLM-KはOllama、LM Studio、Claude、OpenAIなど、様々なLLMサービスに接続できるMacクライアントアプリです。ソースコードをダウンロードしてビルドするか、[Apple App Store](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)からLLM-Kアプリをダウンロードできます。

## 概要

LLM-Kは多様なLLMプラットフォームをサポートする多目的クライアントです：
- Ollama：ローカルでLLMを実行できるオープンソースソフトウェア
- LM Studio：様々なモデルをサポートするローカルLLMプラットフォーム
- Claude：Anthropicの高度なAIモデル
- OpenAI：GPTモデルを含む先進的なAIプラットフォーム

![poster](image_en.jpg)

## 主な機能

- **マルチLLMプラットフォームサポート**：
  - Ollamaを通じたローカルLLMアクセス (http://localhost:11434)
  - LM Studio統合 (http://localhost:1234)
  - Claude APIサポート
  - OpenAI APIサポート
- **選択的サービス表示**：モデル選択メニューに表示するLLMサービスを選択可能
- リモートLLMアクセス：IPアドレスを通じてOllama/LM Studioホストに接続
- カスタムプロンプト：カスタム指示設定をサポート
- 様々なオープンソースLLMをサポート（Deepseek、Llama、Gemma、Qwen、Mistralなど）
- カスタマイズ可能な指示設定
- **高度なモデルパラメータ**：直感的なスライダーでTemperature、Top P、Top Kを制御
- **接続テスト**：内蔵のサーバー接続状態チェッカー
- **マルチフォーマットファイルサポート**：画像、PDF文書、テキストファイル
- 画像認識サポート（対応モデルのみ）
- 直感的なチャット形式UI
- 会話履歴：チャットセッションの保存と管理
- 日本語、英語、韓国語、中国語をサポート
- Markdown形式をサポート

![poster](image_settings.jpg)

## 使用方法

1. 好みのLLMプラットフォームを選択：
   - Ollama：コンピュータにOllamaをインストール（[Ollamaダウンロード](https://ollama.com/download)）
   - LM Studio：LM Studioをインストール（[LM Studioウェブサイト](https://lmstudio.ai/)）
   - Claude/OpenAI：各プラットフォームからAPIキーを取得
2. ソースをダウンロードしてXcodeでビルドするか、[App Store](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)からLLM-Kアプリをダウンロード
3. 選択したプラットフォームを設定：
   - Ollama/LM Studio：希望のモデルをインストール
   - Claude/OpenAI：設定にAPIキーを入力
4. ローカルLLM（Ollama/LM Studio）の場合、必要に応じてリモートアクセスを設定
5. LLM-Kを起動し、希望のサービスとモデルを選択
6. 会話を開始！

## システム要件

- ローカルLLM：OllamaまたはLM Studioがインストールされたコンピュータ
- クラウドLLM：ClaudeまたはOpenAIの有効なAPIキー
- ネットワーク接続

## 利点

- ローカルおよびクラウドベースLLM向けのマルチプラットフォームサポート
- 合理化されたインターフェース用の柔軟なサービス選択
- 様々なプラットフォームを通じた高度なAI機能の利用が可能
- プライバシー保護オプション（ローカルLLM）
- プログラミング、創作作業、カジュアルな質問など、多目的に活用可能
- 体系的な会話管理

## 注意事項

- ローカルLLM機能にはOllamaまたはLM Studioのインストールが必要
- ClaudeおよびOpenAIサービスにはAPIキーが必要
- ローカルLLMホストとAPIキーの安全な管理はユーザーの責任

## アプリのダウンロード

- ビルドが困難な方向けに、以下のリンクからアプリをダウンロードできます。
- [https://apps.apple.com/us/app/mac-ollama-client/id6741420139](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)

## ライセンス

LLM-KはGNUライセンスに基づいています。詳細については[LICENSE](LICENSE)ファイルを参照してください。

## お問い合わせ

LLM-Kに関するお問い合わせやバグレポートは、rtlink.park@gmail.comまでメールでご連絡ください。
