<div align='center'>


# ✨ Mac用Olamaクライアント ✨

_Ollama-based LLM Mac client_

[ENGLISH](README.md) •
[한국어](README_KR.md) •
[日本語](README_JP.md) •
[中文](README_CH.md)

</div>

#MacOllama

MacOllamaは、Ollamaがインストールされているコンピュータに接続して大規模言語モデル（LLM）と対話できるMacクライアントアプリです。ソースコードをダウンロードしてビルドするか、[Apple App Store]（https://apps.apple.com/us/app/mac-ollama-client/id6741420139）からMacOllamaアプリをダウンロードできます。

##はじめに

Ollamaは、ローカルコンピュータで大規模言語モデル（LLM）を簡単に実行できるオープンソースソフトウェアです。
MacOllamaを使用してOllamaにアクセスし、さまざまなLLMを活用できます。 MyOllama - Ollamaプログラムを使用すると、自分のコンピュータでLLMを実行して、有料なしでAIモデルと対話できます。

![ポスター](image_en.jpg)

##主な機能

- ローカルLLMアクセス: ローカルLLM接続 http://localhost:11434
- リモートLLMアクセス: IPアドレスでOlamaホストに接続します。
- カスタムプロンプト: カスタムコマンドの設定サポート
- 様々なオープンソースLLM(Deepseek, Llama, Gemma, Qwen, Mistralなど)をサポート。
- カスタムLLMガイドラインの設定
- 画像認識対応(対応機種に限る)
- 直感的なチャット型UI
- 会話履歴：チャットセッションの保存と管理
- 韓国語、英語、日本語、中国語に対応
- マークダウン形式をサポート


![poster](image_settings.jpg)

##の使い方

1. コンピュータにオラマをインストールします（MacOS、Windows、Linuxのサポート）。オラマのインストール方法は「オラマの旗ハブ」（https://ollama.com/download）で確認できます。
2. ソースをダウンロードして Xcode でビルドするか、[App Store] (https://apps.apple.com/us/app/my-ollama/id6738298481) から MyOllama アプリをダウンロードします。
3.オラマに目的のモデルを取り付けます。 [モデルダウンロード](https://ollama.com/search)
4.オラマからリモートでアクセスできるように設定を変更します。参照：[リンク]（http://practical.kr/?p=809）
5. MyOllamaアプリを起動し、OllamaがインストールされているコンピュータのIPアドレスを入力します。
6. 目的の AI モデルを選択し、会話を開始します。

## システム要件

- オラマがインストールされたコンピュータ
- ネットワーク接続

## 利点

- オープンソースLLMを効率的に活用したい開発者や研究者向けに設計されたアプリです。 API呼び出し、プロンプトエンジニアリング、モデルパフォーマンステストなど、さまざまな技術実験に活用できます。
- 無料で提供される高度なAI機能
- 様々なLLMモデルをサポート
- 個人情報保護（ローカルコンピュータで実行）
- プログラミング、創作作業、日常的な質問などに多目的に使用可能。
- 会話内容を文脈に合わせて整理

##注

- このアプリを使用するには、Ollamaがインストールされているコンピュータが必要です。
- オラマホストを設定して管理する責任はユーザー自身にあります。セキュリティ設定に注意してください。

##アプリのダウンロード

- 構築に苦労している人は、以下のリンクからアプリをダウンロードできます。
- [https://apps.apple.com/us/app/mac-ollama-client/id6741420139](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)

##ライセンス

MyOllamaはGNUライセンスに基づいてライセンスされています。詳しくは、[LICENSE]（ライセンス）ファイルをご覧ください。

##連絡先

MyOllamaに関する質問やバグを報告するには、rtlink.park@gmail.comに電子メールを送ってください。