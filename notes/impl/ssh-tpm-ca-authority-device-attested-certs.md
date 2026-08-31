---
id: "url:https://github.com/Foxboron/ssh-tpm-ca-authority"
title: "ssh-tpm-ca-authority — SSH Certificate Authority with device attestation"
project: "ssh-tpm-ca-authority"
version: "（リリースタグなし。POC / work-in-progress）"
language: "Go"
license: "MIT"
url: "https://github.com/Foxboron/ssh-tpm-ca-authority"
type: impl
tags: [ssh, tpm, endorsement-key, ssh-certificate, certificate-authority, device-attestation, oidc]
relevance: high
added: 2026-08-21
---

## 何が実装されているか

TPM の **Endorsement Key (EK)** を照合して、TPM に束縛された**短命（5 分）の SSH 証明書**を発行する Certificate Authority。`ssh-tpm-agent`（同じ作者の TPM 対応 SSH agent）と組み合わせて使う。

**SSH 証明書の発行条件に device attestation を組み込んだ、動く実物。** 本研究のテーマに現時点で最も近い OSS 実装。

## 技術的な構成

- 信頼点: TPM 2.0（EK を device identity として使う）
- 依存: `ssh-tpm-agent` の改変版、sigstore 系の SSO（GitHub OAuth / Google）
- SSH との接続点: **SSH 証明書の発行フロー**（プロトコル自体は変更しない）
- 実装言語: Go / ライセンス MIT

### プロトコルフロー

1. クライアントが `ssh-tpm-add` で自分の TPM の EK を取得する
2. クライアントが CA（`http://127.0.0.1:8080`）に証明書を要求する
3. CA が EK を設定ファイル中の許可デバイス一覧と照合する
4. CA が OIDC 認証（GitHub / Google）を検証する
5. CA が 5 分間有効の SSH 証明書を発行する
6. クライアントがその証明書で対象ホストにパスワードレス認証する

EK は **TPM2_Public Name の hex 表現**として CA に渡される。

## 自研究との関係

（※ここは解釈）

### 借用できる部分

- **「SSH プロトコルを変えずに証明書発行フローに attestation を挟む」という設計**。中心的な問い 1 の選択肢のうち「SSH 証明書の拡張」路線の実証例として引用できる
- EK を device identity にする実装の具体（TPM2_Public Name の hex 表現）
- 短命証明書（5 分）で freshness を担保するという発想。中心的な問い 4 への一つの答え

### 本研究と重なる部分

「TPM に束縛された鍵で SSH 認証する」という目標は共通。

### この実装が**やっていない**こと（＝貢献余地）

ここが重要。以下はすべて本研究の空白地になりうる:

1. **方向が逆** — これは**クライアント → サーバ**（接続元デバイスの認証）であって、本研究の主眼である**接続先ホストの状態証明**ではない。ホスト側が attested であることはこの仕組みでは分からない
2. **attestation ではなく identity にとどまる** — EK の照合は「この TPM は登録済みの個体か」を見るだけで、**PCR / measured boot / ソフトウェアの状態を一切検証していない**。RATS の語で言えば Evidence の appraisal をしていない。厳密には device *identity* であって platform *attestation* ではない
3. **Verifier が存在しない** — Appraisal Policy も Reference Value も無い。CA が許可リストと突き合わせるだけ
4. **freshness はあるが束縛が弱い** — 5 分の短命証明書は再生窓を狭めるが、SSH セッションへの暗号学的束縛ではない
5. **セッションとの結び付きが無い** — 証明書発行時点の状態しか見ておらず、TOCTOU がそのまま残る
6. POC 品質。`127.0.0.1:8080` 固定など運用に耐えない

**つまり「SSH + TPM」の実装は既にあるが、「SSH + attestation（状態の appraisal）」は未踏である**、と論文で書くための具体的な根拠になる。

## 動かすなら

**未検証。** README の記述のみに基づく。実際に動かす場合は TPM 2.0 搭載機（または swtpm）と `ssh-tpm-agent` が要る。

検証したいこと:
- EK 照合の実際の粒度（EK 証明書チェーンまで見るのか、Name の一致だけか）
- 発行された証明書の `extensions` フィールドに何が入るか（ここに Evidence を足せるか）

## 未解決・気になる点

- 同じ作者の `ssh-tpm-agent` のリリースノートには attestation / EK / AK への言及が無い。CA authority 側だけの機能か
- OpenSSH 本体の SSH 証明書形式で `extensions` に任意データを入れた場合、既存の `sshd` は無視して通すか、拒否するか（＝中心的な問い 2 の後方互換性に直結）
- 関連: [[hardwareprotectedssh-bidirectional-tpm-attestation]] は逆に PCR ベースの platform attestation をやっている。両者の差分が「identity vs attestation」の境界を示す
