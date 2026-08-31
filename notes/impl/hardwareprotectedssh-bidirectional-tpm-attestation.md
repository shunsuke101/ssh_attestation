---
id: "url:https://github.com/hdracer/HardwareProtectedSsh"
title: "HardwareProtectedSsh — Enforce TPM remote platform attestation for Linux authentication"
project: "HardwareProtectedSsh"
version: "（リリースタグなし。約 63 commits）"
language: "C++"
license: "GPL-3.0"
url: "https://github.com/hdracer/HardwareProtectedSsh"
type: impl
tags: [ssh, tpm, pam, platform-attestation, aik, sealed-key, bidirectional, tss]
relevance: high
added: 2026-08-21
---

## 何が実装されているか

SSH 認証に **TPM 2.0 による platform attestation を双方向で強制する** Linux 向けの仕組み。README の言葉では「bidirectional enforcement of hardware-protected keys for SSH」。

クライアントとサーバの双方が、以下を相互に検証する:

- 両者がハードウェア信頼点（TPM）を使っていること
- ホストが secure な状態であること
- 認証鍵が **non-exportable**（TPM から取り出せない）こと

**「接続先ホストの状態を SSH 認証時に検証する」という本研究の主眼を、実際に実装している数少ない例。**

## 技術的な構成

- 信頼点: TPM 2.0
- 構成要素: attestation ライブラリ / **PAM モジュール**（platform attestation 用）/ TSS (TPM Software Stack) 連携 / CLI テストユーティリティ
- SSH との接続点: **PAM**（SSH プロトコル自体は変更しない）
- 実装言語: C++ / ライセンス GPL-3.0
- 規模: 約 63 commits、7 stars、3 forks

テスト出力からは、**AIK の確立 / sealed key の生成 / whitelist 照合 / 暗号処理**が動作していることが読み取れる。

## 自研究との関係

（※ここは解釈）

### 借用できる部分

- **AIK を使った platform attestation を SSH 認証フローに組み込む具体的な手順**。[[ssh-tpm-ca-authority-device-attested-certs]] が EK による identity 確認に留まるのに対し、こちらは AIK + sealed key + whitelist という attestation 本来の構成を取っている
- **whitelist 照合**＝ Reference Value の素朴な実装。RATS で言う Appraisal Policy に相当する部分がどう作られているかの実例
- 双方向にするという設計判断そのもの

### 本研究と重なる部分

目標がほぼ同じ。**先行実装として必ず言及・比較すべき対象。**

### この実装が**やっていない**こと（＝貢献余地）

1. **PAM 層で実装しているため、attestation がユーザ認証フェーズに閉じている** — SSH のトランスポート層（ホスト鍵検証・KEX）は素のまま。つまり **TOFU の問題自体は解決されていない**。クライアントは依然として `known_hosts` でホスト鍵を信頼してから PAM に到達する
2. **セッションへの暗号学的束縛が（少なくとも README からは）確認できない** — PAM の外で attestation が成立しても、それが当該 SSH セッションに束縛されている保証が要る
3. **標準化されていない** — RATS の語彙・EAT・CMW のいずれにも準拠していない独自実装。相互運用性が無い
4. **whitelist ベースの素朴な Reference Value 管理** — 大規模運用（中心的な問い 5）には耐えない。CoRIM 等との接続が無い
5. 研究デモ規模で、活動が活発とは言えない

**論文での位置づけ**: 「PAM 層での実装は存在するが、それではトランスポート層の TOFU 問題は解けない」という形で、**本研究がプロトコル層に踏み込む理由**を示す材料として使える。

## 動かすなら

**未検証。** README とテスト出力の記述のみに基づく。C++ / TSS のビルド環境と TPM 2.0（または swtpm）が要る。

検証したいこと:
- PAM モジュールが attestation を検証するタイミングは、SSH のどのフェーズか
- attestation 失敗時に接続がどう切れるか
- 「bidirectional」と言うとき、**サーバ側のホスト状態をクライアントがどう受け取っている**のか。ここが本研究の核心と重なるので最重要

## 未解決・気になる点

- **最終コミット日を確認できていない**（`unknown`）。活動状況の正確な把握が要る
- 論文・技術文書が付随しているか。単独の実装なら学術的な引用は難しく、実装比較としてのみ使うことになる
- 「secure host」の判定に何の PCR を使っているか、whitelist の粒度はどれくらいか
- 関連: [[ssh-tpm-ca-authority-device-attested-certs]] との対比（identity vs attestation、証明書発行時 vs 認証時）
