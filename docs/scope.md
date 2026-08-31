# 調査スコープ

> このファイルは `/collect` の入力。ここを書き換えれば収集の当たり方が変わる。
> 運用しながら**自分の言葉で育てる**こと。初期値は暫定。

## 研究テーマ

SSH に attestation（機器証明）機能を実現する。

現行 SSH のホスト認証は TOFU（Trust On First Use）と静的なホスト鍵に依存する。鍵の所持は証明できても、**接続先ホストが期待した状態のソフトウェア／ハードウェアで動いているか**は検証できない。ホスト鍵が盗まれれば、あるいはホストが改竄されていれば、クライアントは気づけない。

そこで TPM 等のハードウェア信頼点と RATS（RFC 9334）系の attestation 手続きを SSH プロトコルに統合し、**「誰が鍵を持っているか」から「どんな状態のマシンが鍵を持っているか、正常なソフトウェアとハードウェアが動作しているか」へ**認証の意味を拡張する。

### 中心的な問い

1. attestation Evidence を SSH のどのレイヤで運ぶか（トランスポート層の鍵交換 / ユーザ認証 / 新規チャネル / SSH 証明書の拡張フィールド）
2. 既存 OpenSSH との後方互換性・段階的導入をどう担保するか
3. Verifier をどこに置くか（クライアント自身 / 独立した検証サービス / CA 兼務）
4. Freshness をどう保証するか（nonce の運び方、セッション束縛、再生攻撃対策）
5. 検証コストとハンドシェイクのレイテンシ、大規模運用時の Reference Value 管理

### 対称性のメモ

attestation は**サーバ→クライアント**（接続先ホストは正しい状態か）と**クライアント→サーバ**（接続元端末は正しい状態か、＝ device trust）の両方向がある。どちらも収集対象。後者は商用製品が先行しているので `industry` カテゴリで拾えることが多い。

---

## 検索キーワード

英語で検索する。日本語検索は基本的に不要（ヒットが少なくノイズが多い）。

### 中核（必ず回す）

```
SSH attestation
remote attestation SSH
TPM-backed SSH key
attested SSH host key
hardware-rooted host authentication
SSH host key trust on first use replacement
```

### 隣接領域（ローテーションで回す）

**Attestation 一般 / 標準**
```
RATS remote attestation procedures
Entity Attestation Token EAT
attestation evidence appraisal policy
reference values RIM CoRIM
background-check model attestation
passport model attestation
```

**ハードウェア信頼点**
```
TPM 2.0 attestation key AK
measured boot PCR quote
DICE layered attestation
confidential computing attestation SEV-SNP TDX
secure enclave attestation SGX
```

**OS / 実行環境の完全性**
```
Linux IMA EVM integrity measurement
runtime attestation control flow integrity
Keylime remote attestation
```

**鍵と認証まわり**
```
SSH certificate authority ephemeral credentials
FIDO2 SSH security key resident key
WebAuthn attestation statement
device identity IDevID IEEE 802.1AR
zero trust device posture SSH
```

**プロトコル設計**
```
channel binding attestation
freshness nonce attestation replay
attestation privacy DAA anonymous attestation
sshの詳細な設計

### 検索式の組み方

Web 検索は `"SSH" AND ("remote attestation" OR "TPM")` のように**中核語と隣接語を掛ける**。単独で `remote attestation` だけ投げると Confidential Computing の一般記事で埋まる。

---

## 除外条件（ノイズ潰し）

以下に該当するものは `inbox` にすら載せず捨てる。**この節がこのファイルで一番効く。**

- **SSH 運用 Tips 記事** — 鍵の作り方、`sshd_config` の設定解説、踏み台の立て方。attestation に触れていないもの。
- **TPM の概説記事** — 「TPM とは何か」「Windows 11 の TPM 2.0 要件」。新規の技術的主張がないもの。
- **ブロックチェーン文脈の "attestation"** — EAS（Ethereum Attestation Service）、検証可能クレデンシャル、on-chain attestation。語が同じだけで別分野。
- **監査・コンプライアンス文脈の "attestation"** — SOC 2 attestation、会計監査。完全に別語義。
- **ベンダのマーケティング記事** — 技術的中身（プロトコル、脅威モデル、実装、評価）が無い製品紹介。ただし**新機能の初出リリース**は `industry` として拾う。
- **CVE / 脆弱性速報** — 単発の SSH 脆弱性は、attestation で緩和できる類のもの（ホスト鍵漏洩、サプライチェーン改竄）でない限り対象外。
- **既知の教科書的内容** — RFC 4251〜4254（SSH 基本仕様）の解説など。仕様そのものは `notes/specs/` に一度置けば十分。

### 判断に迷ったら

「これは自分の論文の Related Work か Background に引用しうるか？」で判断する。引用しないなら `low` にして inbox 止まり、または捨てる。

---

## Relevance の判定基準

| 値 | 基準 | 扱い |
|---|---|---|
| `high` | SSH と attestation の**両方**に直接関わる。または自研究の設計判断（上の「中心的な問い」）に影響する。あるいは Related Work に確実に引用する | `notes/` にノートを起こす。論文なら BibTeX にも追記 |
| `medium` | 片方だけに関わるが、部品・前提として使える。関連手法として言及しうる | inbox のみ。後で `/survey` の起点にする |
| `low` | 分野の背景として一応記録するが、引用の見込みは薄い | inbox のみ。1 行で済ませる |

**`high` は絞る。** 1 回の `/collect` で `high` が 5 件を超えたら判定が緩んでいる。ノートが増えすぎると読み返さなくなる。

---

## 時間範囲

- 定期収集は**前回の `/collect` 以降**の新着が対象（`state/seen.jsonl` で判定）。
- 初回のみ、過去に遡って基礎文献を拾う。目安は **2019 年以降**。ただし RFC 9334（RATS Architecture）、TPM 2.0 仕様、RFC 4251〜4254 のような**土台となる文献は年に関係なく拾う**。
