# 用語集

> ノートを書くときの表記統一のため。訳語を固定し、揺れを防ぐ。
> **原則は英語原文のまま使う。** 日本語併記は初出時のみ。

## RATS（RFC 9334）の役割語

RATS のアーキテクチャ用語は**訳さず英語のまま**使う。訳すと役割の対応関係が壊れる。

| 用語 | 意味 | 本研究での対応物（想定） |
|---|---|---|
| **Attester** | Evidence を生成する主体 | attestation する側の SSH ホスト（またはクライアント端末） |
| **Verifier** | Evidence を Appraisal Policy に照らして評価し、Attestation Result を出す | SSH クライアント自身、または独立した検証サービス |
| **Relying Party** | Attestation Result を受けて、アクセス可否などを判断する | SSH クライアント（接続するか否かを決める） |
| **Endorser** | Attester のハードウェアの真正性を保証する（製造者など） | TPM ベンダ、EK 証明書の発行者 |
| **Reference Value Provider** | 「正しい状態」の基準値を提供する | OS ディストリビュータ、自組織のビルドシステム |
| **Evidence** | Attester が出す主張（PCR quote など） | TPM Quote + イベントログ |
| **Attestation Result** | Verifier の評価結果 | 「このホストは信頼できる状態」という署名付き判断 |
| **Appraisal Policy** | 評価の基準 | 期待 PCR 値、許容するファームウェア版など |

### 2 つのトポロジ

| モデル | 流れ | 特徴 |
|---|---|---|
| **Background-Check Model** | Attester → Relying Party → Verifier → Relying Party | Relying Party が Verifier に問い合わせる。Verifier の集中管理がしやすい |
| **Passport Model** | Attester → Verifier → Attester → Relying Party | Attester が事前に Attestation Result（=passport）を取得して提示。接続時のレイテンシが小さい |

SSH への統合を考えるとき、**どちらのモデルを採るかが最初の設計判断**になる。

---

## ハードウェア信頼点

| 用語 | 説明 |
|---|---|
| **TPM (Trusted Platform Module)** | ハードウェア信頼点。鍵の保護と測定値の保持を行う。TPM 2.0 が現行 |
| **PCR (Platform Configuration Register)** | 測定値を extend 演算で累積するレジスタ。上書きできず、順序が値に反映される |
| **Quote** | 指定 PCR 群の値に AK で署名したもの。Evidence の中核 |
| **EK (Endorsement Key)** | TPM 固有の、製造時に埋め込まれる鍵。デバイス識別に使えるがプライバシー上そのままは使わない |
| **AK / AIK (Attestation Key / Attestation Identity Key)** | Quote への署名専用の鍵。EK から導出・証明される |
| **SRK (Storage Root Key)** | 鍵階層の根。他の鍵を封印（seal）する |
| **Measured Boot** | 起動の各段階が次段階を測定して PCR に extend していく仕組み |
| **Secure Boot** | 署名検証に失敗したら起動を止める仕組み。Measured Boot とは**別物**（記録 vs 阻止） |
| **DICE (Device Identifier Composition Engine)** | 階層的に鍵と識別子を導出する軽量な信頼点。TCG 仕様。組込み向け |
| **IDevID / LDevID** | IEEE 802.1AR のデバイス初期／ローカル識別子 |
| **TEE (Trusted Execution Environment)** | 隔離実行環境の総称。SGX / SEV-SNP / TDX / TrustZone / CCA など |
| **Confidential Computing** | 使用中データの保護を TEE で行うアプローチ。attestation が前提技術 |

---

## 完全性の測定

| 用語 | 説明 |
|---|---|
| **IMA (Integrity Measurement Architecture)** | Linux カーネルの機能。実行されるファイルを測定して PCR に extend し、測定ログを残す |
| **EVM (Extended Verification Module)** | ファイルのメタデータ完全性を守る IMA の相棒 |
| **Static Attestation** | 起動時点の状態の証明。実行中の改竄は捕らえられない |
| **Runtime Attestation** | 実行中の状態の証明。制御フロー完全性などを対象にする。コストが高い |
| **TOCTOU (Time-Of-Check to Time-Of-Use)** | 検証した瞬間と使う瞬間の間に状態が変わる問題。attestation の根本的な限界のひとつ |
| **Freshness** | Evidence が古くないことの保証。nonce・タイムスタンプ・エポックで担保する |
| **RIM (Reference Integrity Manifest) / CoRIM** | 「正しい測定値」を配布するための形式。CoRIM は CBOR 版 |

---

## Evidence の形式

| 用語 | 説明 |
|---|---|
| **EAT (Entity Attestation Token)** | IETF RATS の attestation トークン形式。CWT/JWT ベース |
| **CWT / JWT** | CBOR / JSON ベースの Web トークン |
| **COSE / JOSE** | CBOR / JSON 向けの署名・暗号化フレームワーク |
| **DAA (Direct Anonymous Attestation)** | 個体を特定せずに attestation する方式。プライバシー対策 |
| **Privacy CA** | AK 証明書を発行して EK を隠す仲介者 |

---

## SSH 側

| 用語 | 説明 |
|---|---|
| **TOFU (Trust On First Use)** | 初回接続時のホスト鍵を無検証で受け入れ、以後それを信頼するモデル。**本研究が置き換えたい対象** |
| **`known_hosts`** | TOFU で受け入れたホスト鍵の台帳 |
| **SSHFP** | ホスト鍵の指紋を DNS に置く仕組み（RFC 4255）。DNSSEC 前提 |
| **SSH Certificate** | OpenSSH 独自のホスト／ユーザ証明書。`critical options` と `extensions` フィールドを持つ。**attestation 情報の運び先候補** |
| **KEX (Key Exchange)** | SSH の鍵交換フェーズ。ここでホスト鍵の所持証明が行われる |
| **`ssh-agent`** | 秘密鍵を保持し署名を代行するデーモン。TPM 連携の実装点 |
| **FIDO/U2F key type** | OpenSSH 8.2 以降の `ecdsa-sk` / `ed25519-sk`。**セキュリティキーの attestation 情報を扱える既存の前例**として重要 |
| **Channel Binding** | 上位層の認証を下位層のセッションに束縛すること。attestation の再生防止に必須 |
| **Device Trust** | 接続元端末の状態を条件にアクセスを許す商用機能の呼称（Teleport 等） |

---

## 表記の統一ルール

- RATS の役割語（Attester, Verifier, Relying Party, Evidence, Attestation Result）は**常に英語・大文字始まり**。
- `attestation` は訳さない。「アテステーション」とカタカナ表記もしない。
- `TOFU` は初出時のみ `TOFU (Trust On First Use)` と展開する。
- 製品名・プロジェクト名は公式表記に従う（`OpenSSH`, `Teleport`, `Keylime`, `Tailscale`）。
- PCR 番号は `PCR[0-7]` のように角括弧で書く。
