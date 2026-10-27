# 調査スコープ

> このファイルは `/collect` の入力。ここを書き換えれば収集の当たり方が変わる。
> 運用しながら**自分の言葉で育てる**こと。初期値は暫定。

## 研究テーマ

SSH に attestation（機器証明）機能を実現する。**attestation をクライアント認証に拡張する。**

現行 SSH のクライアント認証（`publickey` 等）は鍵の所持しか証明しない。仕様自身が `The use of public key authentication assumes that the client host has not been compromised.`（RFC 4251 §9.4.4）と書いている通り、**接続元の端末が期待した状態のソフトウェア／ハードウェアで動いているか**をサーバーは検証できない。鍵が盗まれれば、あるいは端末が改竄されていれば、サーバーは気づけない。

そこで TPM 等のハードウェア信頼点を使った challenge-response 型の remote attestation を SSH のクライアント認証に組み込み、**「誰が鍵を持っているか」から「どんな状態の端末が鍵を持っているか」へ**認証の意味を拡張する。

- **server からの challenge** によって、attestation の freshness を担保する
- **client からの response**（TPM Quote 等の Evidence）によって、client の完全性を server が保証する

RATS の役割では Attester = SSH クライアント、Verifier / Relying Party = SSH サーバー。設計の土台は RFC 9334（RATS Architecture）、RFC 9683（TPM ベースの Remote Integrity Verification）、draft-ietf-rats-reference-interaction-models（Challenge/Response Remote Attestation）。

### 中心的な問い

1. server の challenge と client の Evidence を SSH のどのレイヤで運ぶか（ユーザ認証の新方式 / トランスポート層の鍵交換・`SSH_MSG_EXT_INFO` / 新規チャネル・グローバル要求 / SSH ユーザ証明書の拡張フィールド）
2. 既存 OpenSSH との後方互換性・段階的導入をどう担保するか
3. Verifier をどこに置くか（サーバー自身 / 独立した検証サービス / CA 兼務）
4. Freshness をどう保証するか（server challenge の生成と運び方、SSH セッションへの束縛、再生攻撃対策、タイムスタンプ）
5. 検証コストとハンドシェイクのレイテンシ、大規模運用時の Reference Value 管理

### 方向のメモ

attestation には**クライアント→サーバー**（接続元端末は正しい状態か、＝ device trust）と**サーバー→クライアント**（接続先ホストは正しい状態か）の両方向がある。**本研究の対象は前者**。

- クライアント→サーバー: 本研究の対象。商用製品（device trust）が先行しているので `industry` カテゴリで拾えることが多い
- サーバー→クライアント（ホスト attestation、TOFU の置き換え）: 対象外。ただし SSH への attestation 統合という点で設計が参考になるので、**対比用に `medium` 以下で**拾う

### 並行テーマ: NETCONF / YANG による remote attestation

SSH のクライアント認証とは独立に並行して進める別テーマ。RISC-V の QEMU guest（swtpm が TPM 2.0 として見える）を Attester、WSL2 の host を Verifier とし、NETCONF（netopeer2 + sysrepo）上で RFC 9684 の YANG `ietf-tpm-remote-attestation` を使って challenge-response remote attestation を行う。Verifier は RPC `tpm20-challenge-response-attestation` で nonce と PCR selection を送り、Attester は sysrepo-plugind の plugin `rats-attester.so` で RPC を受けて TPM2_Quote の結果（`quote-data`、`quote-signature`、`unsigned-pcr-values`）を返す。Verifier は署名、nonce、PCR digest、Reference Value を照合して合否を判定する。

NETCONF は SSH の上で動くので、**Attester = NETCONF / SSH サーバー側**になる。RFC 9683 の RIV と同じ向きで、主テーマとは逆。**SSH に触れていない文献でも、この環境に直結すれば `high` にしてよい**（下の「Relevance の判定基準」を参照）。

#### 中心的な問い（暫定。人間が書き直すこと）

1. RFC 9684 の YANG モデルを sysrepo plugin でどう実装するか。出力ノード名が文書内で揺れている（YANG モジュールでは `quote-data`、tree 図では `TPMS_QUOTE_INFO`、XML の例では `attestation-data`）点をどう扱うか
2. Verifier の判定条件（署名、nonce、PCR digest、Reference Value）をどう実装し、判定漏れ（nonce を照合しない等）をどう防ぐか
3. Reference Value をどう用意・管理するか（CoRIM、TCG RIM）
4. event log を返さず `unsigned-pcr-values` だけを返す構成で、何が検証でき、何が検証できないか

---

## 検索キーワード

英語で検索する。日本語検索は基本的に不要（ヒットが少なくノイズが多い）。

### 中核（必ず回す）

```
SSH attestation
remote attestation SSH
TPM-backed SSH key
SSH client attestation
device attestation SSH client authentication
TPM quote SSH user authentication
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
challenge-response remote attestation
reference interaction models remote attestation
remote integrity verification TPM
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
```

**逆方向（対比用。`medium` 以下で拾う）**
```
attested SSH host key
hardware-rooted host authentication
SSH host key trust on first use replacement
```

### 並行テーマ（必ず回す）

NETCONF / YANG による remote attestation のテーマ用。**主テーマのキーワードとは別に回す。**

**NETCONF / YANG による attestation**
```
RFC 9684 CHARRA YANG
ietf-tpm-remote-attestation
tpm20-challenge-response-attestation
NETCONF remote attestation TPM
YANG data model remote attestation
RESTCONF remote attestation
attestation event stream subscription YANG
netopeer2 sysrepo attestation
```

**Verifier の判定**
```
TPM2_Quote verification
TPMS_ATTEST quote signature verification
PCR digest verification quote
attestation nonce qualifyingData freshness check
reference value PCR appraisal
TPM event log replay verification
verifier implementation remote attestation TPM
attestation results AR4SI EAR
```

### 検索式の組み方

Web 検索は `"SSH" AND ("remote attestation" OR "TPM")` のように**中核語と隣接語を掛ける**。単独で `remote attestation` だけ投げると Confidential Computing の一般記事で埋まる。

並行テーマも同様に掛ける。NETCONF / YANG は `("NETCONF" OR "YANG" OR "RFC 9684") AND ("remote attestation" OR "TPM")`、Verifier の判定は `("TPM2_Quote" OR "TPM quote") AND ("verification" OR "verifier" OR "appraisal")` を基本形にする。

---

## 除外条件（ノイズ潰し）

以下に該当するものは `inbox` にすら載せず捨てる。**この節がこのファイルで一番効く。**

- **SSH 運用 Tips 記事** — 鍵の作り方、`sshd_config` の設定解説、踏み台の立て方。attestation に触れていないもの。
- **TPM の概説記事** — 「TPM とは何か」「Windows 11 の TPM 2.0 要件」。新規の技術的主張がないもの。
- **ブロックチェーン文脈の "attestation"** — EAS（Ethereum Attestation Service）、検証可能クレデンシャル、on-chain attestation。語が同じだけで別分野。
- **監査・コンプライアンス文脈の "attestation"** — SOC 2 attestation、会計監査。完全に別語義。
- **ベンダのマーケティング記事** — 技術的中身（プロトコル、脅威モデル、実装、評価）が無い製品紹介。ただし**新機能の初出リリース**は `industry` として拾う。
- **CVE / 脆弱性速報** — 単発の SSH 脆弱性は、attestation で緩和できる類のもの（クライアント鍵の窃取、クライアント端末の改竄、サプライチェーン改竄）でない限り対象外。
- **既知の教科書的内容** — RFC 4251〜4254（SSH 基本仕様）の解説など。仕様そのものは `notes/specs/` に一度置けば十分。
- **attestation に触れない NETCONF / YANG の記事** — 設定管理一般、YANG モデルの書き方、NETCONF の導入手順。並行テーマでも attestation / TPM に触れないものは捨てる。
- **netopeer2 / sysrepo のビルド・設定記事** — 研究環境で使っていても、attestation の実装に関わらないものは対象外。
- **TPM ツールの使い方記事** — `tpm2_quote` / `tpm2_checkquote` のコマンド例だけで、検証手法についての主張がないもの。
- **RISC-V・仮想 TPM 単独の文献** — 研究環境で使っているが、今は探索対象に加えていない（`CLAUDE.md` の「論文探索の範囲」参照）。attestation の判定や NETCONF / YANG に直接関わる場合だけ拾う。

### 判断に迷ったら

「これは自分の論文の Related Work か Background に引用しうるか？」で判断する。引用しないなら `low` にして inbox 止まり、または捨てる。

---

## Relevance の判定基準

| 値 | 基準 | 扱い |
|---|---|---|
| `high` | SSH と attestation の**両方**に直接関わる。または自研究の設計判断（上の「中心的な問い」）に影響する。あるいは Related Work に確実に引用する。**並行テーマでは、NETCONF / YANG と attestation の両方に直接関わるもの、または Verifier の判定条件の設計に影響するもの** | `notes/` にノートを起こす。論文なら BibTeX にも追記 |
| `medium` | 片方だけに関わるが、部品・前提として使える。関連手法として言及しうる | inbox のみ。後で `/survey` の起点にする |
| `low` | 分野の背景として一応記録するが、引用の見込みは薄い | inbox のみ。1 行で済ませる |

**`high` は絞る。** 1 回の `/collect` で `high` が 5 件を超えたら判定が緩んでいる。ノートが増えすぎると読み返さなくなる。上限は両テーマの合計で数える。

**並行テーマ由来の行は、inbox の 1 行要約の頭に `[並行]` を付ける。** `/digest` でテーマ別に畳めるようにするため。

---

## 時間範囲

- 定期収集は**前回の `/collect` 以降**の新着が対象（`state/seen.jsonl` で判定）。
- 初回のみ、過去に遡って基礎文献を拾う。目安は **2019 年以降**。ただし RFC 9334（RATS Architecture）、RFC 9683（TPM ベースの Remote Integrity Verification）、RFC 9684（CHARRA YANG）、Reference Interaction Models for Remote Attestation Procedures、TPM 2.0 仕様、RFC 4251〜4254 のような**土台となる文献は年に関係なく拾う**。
- **並行テーマは 2026-10-26 に追加した。** `docs/sources.md` で最終確認日が `—` の並行テーマ用巡回先は初回扱いとし、上と同じく 2019 年以降と土台文献まで遡る。ただし impl のリリース一覧は遡らず、最新版だけを登録する。
- **並行テーマの土台の一部は既読として埋もれている。** `rfc:9684`、`draft:ietf-rats-network-device-subscription-13`、`draft:ietf-rats-corim-11`、`draft:ietf-rats-ar4si-10`、`draft:ietf-rats-ear-04` は主テーマの基準で `medium` として `state/seen.jsonl` に登録済みのため、`/collect` では再出現しない。並行テーマでの再判定は `/survey` で行う。
