---
id: "tpm2-library:185"
title: "Trusted Platform Module 2.0 Library, Version 185"
body: "TCG"
status: "TCG Published"
year: 2026
url: "https://trustedcomputinggroup.org/resource/tpm-library-specification/"
type: spec
tags: [tpm, tcg, tpm2-library, tpm2-quote, tpms-attest, qualifying-data, clock-info, restricted-signing-key, pqc, ml-dsa, ml-kem, v185]
relevance: high
added: 2026-09-15
---

## 何を規定しているか

TCG（Trusted Computing Group）が策定する **TPM 2.0 の本体仕様**。TPM が持つべきコマンド、データ構造、アーキテクチャ（鍵階層、PCR、認可、attestation）を規定する。本研究で「Evidence の中身」と呼んでいるもの——PCR Quote とその署名構造——の一次出典。

**2026-09-15 時点の最新版は Version 185（2026-03-12、TCG Published）**。4 部構成で、全 Part が同日付:

| Part | タイトル | 本ノートで読んだ箇所 |
|---|---|---|
| Part 0 | Introduction | 変更履歴（§2）、非推奨機能（§3） |
| Part 1 | Architecture | §28 Attestation、§46 ML-DSA、§47 ML-KEM |
| Part 2 | Structures | §10.2 ハッシュ構造、§10.3.3 `TPM2B_DATA`、§10.10 `TPMS_CLOCK_INFO`、§10.11 attestation 構造、§8.3.3.14 `TPMA_OBJECT.sign` |
| Part 3 | Commands | §18.1 attestation コマンド総論、§18.4 `TPM2_Quote` |

### 版の系譜

| 版 | 時期 | 備考 |
|---|---|---|
| 1.83 | 2024（TCG の参照実装 GitHub リリース `V183` は 2024-03-21） | firmware-limited / SVN-limited 階層を導入 |
| **184** | 参照実装 GitHub リリース `V184` は 2025-10-06 | **版番号の付け方を変更**（1.84 ではなく 184）。Part 0 を新設、Part 4 への参照を削除 |
| **185** | **2026-03-12** | **PQC（ML-DSA / ML-KEM）を導入**。参照実装の `V185` タグは 2026-09-15 時点で GitHub に未公開 |

途中の Release Candidate として RC2（2025-07-10）と RC4（2025-12-12）が TCG サイト上に存在する（ファイル名から判断。中身は未確認）。

### 取得経路についての注記

TCG のサイト（`trustedcomputinggroup.org`）は Cloudflare のボット対策で機械的な取得を拒否する（HTTP 403）。本ノートは以下の正規 URL の **Internet Archive 上のコピー**から取得した PDF を `pdftotext` でテキスト化して読んだ。表紙の版番号・日付・`TCG Published` の表記は全 Part で確認済み。

- Part 0: `https://trustedcomputinggroup.org/wp-content/uploads/Trusted-Platform-Module-2.0-Library-Part-0-Introduction_Version-185_pub.pdf`
- Part 1: `https://trustedcomputinggroup.org/wp-content/uploads/Trusted-Platform-Module-2.0-Library-Part-1-Architecture_Version-185_pub.pdf`
- Part 2: `https://trustedcomputinggroup.org/wp-content/uploads/Trusted-Platform-Module-2.0-Library-Part-2-Structures_Version-185_pub.pdf`
- Part 3: `https://trustedcomputinggroup.org/wp-content/uploads/Trusted-Platform-Module-2.0-Library-Part-3-Commands_Version-185_pub.pdf`

## 184 と 185 で何が変わったか（Part 0 §2, §3）

### Version 184

- 版番号を `TPM_SPEC_VERSION` ベースに変更（184）
- Part 0: Introduction を新設。Part 4 への参照を削除
- `TPM2_ReadOnlyControl()` と Read-Only モードを導入
- `TPM2_PolicyTransportSPDM()` を導入
- **非推奨**: `TPM_ALG_TDES`、**`TPM_ALG_SHA1`**、`TPM2_CreateLoaded()`、**`TPM2_CertifyX509()`**、Attached Components

### Version 185

- **ML-DSA、HashML-DSA、ML-KEM を導入**
- EdDSA、HashEdDSA、DHKEM を導入
- **逐次署名コマンド**を導入: `TPM2_SignSequenceStart()` / `TPM2_SignSequenceComplete()` / `TPM2_VerifySequenceStart()` / `TPM2_VerifySequenceComplete()`——任意長のメッセージに署名・検証できる
- **digest 署名コマンド**を導入: `TPM2_SignDigest()` / `TPM2_VerifyDigestSignature()`
- KEM コマンドを導入: `TPM2_Encapsulate()` / `TPM2_Decapsulate()`
- 制限付き復号の「Secret Sharing」を「Labeled KEM」として再定義し、ML-KEM ベースの Labeled KEM を定義
- 公開鍵のみのオブジェクトの永続化を可能に
- `TPM_PT_DAY_OF_YEAR` を `TPM_PT_ERRATA` に改名。**TPM が実装する errata の版が日付ではなく版番号で報告されるように**
- **非推奨**: `TPM2_Sign()` と `TPM2_VerifySignature()`（PQC に対応するため新コマンドに置換）、sign と decrypt の両方が SET された鍵、NULL スキームの鍵（ストレージ鍵等を除く）、`TPMA_ALGORITHM` の全ビット、**非制限鍵による salted session**

非推奨の理由として明記されているもの:

> TPM2_Sign() was deprecated in TPM 2.0 version 185. Its functionality is replaced by TPM2_SignDigest() and the sequenced signing commands, which were introduced in order to accommodate post-quantum algorithms. — Part 0, §3.1.3.5

> SHA1 will be withdrawn by NIST on January 1, 2031. Users should prefer a more modern hash algorithm, such as SHA256, instead. — Part 0, §3.1.1.2

> TPM2_CertifyX509() was deprecated in TPM 2.0 version 184 because its nuances caused confusion. Where possible, users should adopt TPM2_Certify() with an Attestation Key instead. — Part 0, §3.1.3.3

**`TPM2_Quote()` は非推奨になっていない。**

## 本研究に効く定義・要件

### `TPM2_Quote()`（Part 3 §18.4）

> This command is used to quote PCR values. — Part 3, §18.4.1

| 方向 | フィールド | 型 | 内容 |
|---|---|---|---|
| ハンドル | `signHandle` | `TPMI_DH_OBJECT+` | 署名鍵。Auth Role: USER |
| 入力 | **`qualifyingData`** | **`TPM2B_DATA`** | **呼び出し側が与えるデータ**（nonce を入れる場所） |
| 入力 | `inScheme` | `TPMT_SIG_SCHEME+` | 鍵のスキームが NULL のときに使う署名スキーム |
| 入力 | `PCRselect` | `TPML_PCR_SELECTION` | Quote する PCR の集合 |
| 出力 | `quoted` | `TPM2B_ATTEST` | 署名対象の構造体 |
| 出力 | `signature` | `TPMT_SIGNATURE` | `quoted` への署名 |

PCR ダイジェストは「選択された PCR の値を連結し、署名スキームのハッシュでハッシュしたもの」。署名スキームかそのハッシュが `TPM_ALG_NULL` なら `TPM_RC_SCHEME` を返さなければならない。

**185 での変更**: `signHandle` が `TPM_RH_NULL` の場合、署名なし（NULL Signature）の `TPMS_ATTEST` を返す。1.83 以前は `TPM_RC_SCHEME` を返すことが許されていた。

### `TPMS_ATTEST` — 署名される構造体（Part 2 §10.11.12、Part 1 §28.2）

| フィールド | 型 | 内容 |
|---|---|---|
| `magic` | `TPM_CONSTANTS32` | 常に `TPM_GENERATED_VALUE`（`0xff544347`） |
| `type` | `TPMI_ST_ATTEST` | 構造体の種別（Quote なら `TPM_ST_ATTEST_QUOTE`） |
| `qualifiedSigner` | `TPM2B_NAME` | 署名鍵の Qualified Name |
| **`extraData`** | **`TPM2B_DATA`** | **呼び出し側が与えた外部情報（`qualifyingData` がここに入る）** |
| **`clockInfo`** | **`TPMS_CLOCK_INFO`** | Clock、resetCount、restartCount、Safe |
| `firmwareVersion` | `UINT64` | TPM ベンダ固有のファームウェア版 |
| `attested` | `TPMU_ATTEST` | 種別ごとの中身。Quote なら `TPMS_QUOTE_INFO`（`pcrSelect` と `pcrDigest`） |

**`magic` が偽造防止の要。** 制限付き署名鍵は、TPM 自身が生成したのではない、`TPM_GENERATED_VALUE` で始まるデータには署名しない:

> A TPM will not allow a restricted signing key to sign any external data if that data starts with this unique value. The way that the TPM enforces this restriction is that a TPM will not use a restricted key to sign a digest that the TPM did not produce. — Part 1, §28.2

逆に**非制限鍵では attestation を偽造できる**:

> Attestation commands typically use a restricted, sensitiveDataOrigin signing key. A key that is not restricted can sign any digest and would permit a forged attestation. It is common to use a fixedTPM key. — Part 3, §18.1

### `qualifyingData` のサイズ上限（Part 2 §10.2, §10.3.3、Part 1 §28.4）

> Each of the attestation commands has a parameter called qualifyingData. This parameter is not interpreted by the TPM and may contain any data chosen by the caller. The most common use of this parameter is expected to be as a nonce to ensure "freshness" of an attestation. — Part 1, §28.4

型は `TPM2B_DATA` で、その `buffer` の上限は **`sizeof(TPMT_HA)`**。`TPMT_HA` は `hashAlg`（`TPMI_ALG_HASH`、2 オクテット）と `digest`（`TPMU_HA`）の組であり、`TPMU_HA` は「**その TPM が実装する**全ハッシュアルゴリズムの union」と定義されている（Part 2 §10.2.1）。

したがって:

> **`qualifyingData` の最大長 = 2 オクテット + その TPM が実装する最長のダイジェスト長**

| TPM が実装する最長ハッシュ | `qualifyingData` の上限 |
|---|---|
| SHA-256 | 34 オクテット |
| SHA-384 | 50 オクテット |
| SHA-512 / SHA3-512 | 66 オクテット |

Part 1 §28.2 はこの領域を「ダイジェストと、そのダイジェストの構成要素を示す **method indicator** を入れる余地」と説明し、method indicator の定義は仕様の範囲外としている。

### `TPMS_CLOCK_INFO` — nonce 以外の鮮度材料（Part 2 §10.10）

| フィールド | 型 | 意味 |
|---|---|---|
| `clock` | `UINT64` | TPM に電源が入っている間進むミリ秒単位の時刻。単調増加。`TPM2_Clear()` で 0 に戻り、`TPM2_ClockSet()` で進められる。**原点の解釈は仕様の範囲外**（UTC が一般的な慣行と想定） |
| `resetCount` | `UINT32` | 最後の `TPM2_Clear()` 以降の **TPM Reset**（≒再起動）の回数 |
| `restartCount` | `UINT32` | 最後の TPM Reset または `TPM2_Clear()` 以降に `TPM2_Shutdown()` か `_TPM_Hash_Start` が起きた回数（Restart / Resume） |
| `safe` | `TPMI_YES_NO` | 現在の `clock` より大きい値を過去に報告したことがない、の保証 |

`clock` の不揮発部分は少なくとも 2^22 ミリ秒（約 69.9 分）ごとに更新されなければならない。

### プライバシー用の難読化（Part 3 §18.1、Part 1 §28.3）

`resetCount` / `restartCount` / `firmwareVersion` の組み合わせは TPM を一意に近く特定しうるので、**署名鍵が Endorsement 階層にも Platform 階層にもない場合、鍵ごとに異なるオフセットを加えて難読化**する。オフセットは `KDFa(signHandle の nameAlg, shProof, "OBFUSCATE", signHandle の QN, 0, 128)` から導出される。

> Although the values are obfuscated, they do not lose any of their usefulness for indicating changes to the values. While the absolute values are not visible in the attestation, it is still possible to look at attestations signed by the same key and determine how many times the TPM was reset or restarted between the attestations. — Part 1, §28.3

### PQC 署名の扱い（Part 1 §46）

- ML-DSA の秘密鍵は 32 バイトのシードとして表現され、インポート／エクスポートもシードでのみ行う
- **ML-DSA 鍵は逐次署名コマンドで使う**。`allowExternalMu` が TRUE の場合に限り `TPM2_SignDigest()` でも使え、そのときダイジェストは FIPS 204 の 64 バイトの外部 μ として解釈される
- HashML-DSA 鍵は逐次署名コマンドと `TPM2_SignDigest()` の両方で使える

## 拡張点・自由度

- **`qualifyingData` の中身は TPM が解釈しない**（Part 1 §28.4）。何を入れるか、method indicator をどう定義するかは完全に呼び出し側の自由
- `clock` の原点の解釈は範囲外（Part 2 §10.10.1）
- `firmwareVersion` の値の意味は TPM ベンダ固有
- どの PCR に何を測定するかは Library 仕様ではなく**プラットフォーム仕様**（TCG PC Client Platform Firmware Profile 等）の管轄
- AK の証明（EK 証明書からの連鎖、`TPM2_MakeCredential()` / `TPM2_ActivateCredential()`）の**運用プロトコル**は規定しない。プリミティブだけを与える

## 他仕様との関係

- **プラットフォームプロファイル**: TCG PC Client Platform TPM Profile (PTP)。検索結果の要約では「v1.07（2026-03-23）が Library 185 以降への準拠を要求」とされるが、**PDF が TCG サイトから取得できず未確認**
- **ISO/IEC 11889**: Part 0 の変更履歴に ISO/IEC 11889:2015 の FDIS 投票への言及がある（旧版の国際標準化）。**185 と ISO 版の対応関係は未確認**
- **参照実装**: <https://github.com/TrustedComputingGroup/TPM>。リリースは `V183`（2024-03-21）と `V184`（2025-10-06）まで
- **RATS 側での使われ方**: [[rfc9683-riv-tpm-network-devices]]（TPM Quote をネットワーク機器の完全性検証に使う）、RFC 9684（CHARRA YANG）
- **Handle との対応**: [[draft-ietf-rats-reference-interaction-models]] の Handle（attestation nonce）が、TPM 側では `qualifyingData` → `TPMS_ATTEST.extraData` として署名対象に入る
- **SSH 側で nonce 供給源となる値**: [[rfc4253-ssh-transport-layer]]（exchange hash H）、[[rfc8308-ssh-extension-negotiation]]

## 引用すべき箇所

> Attestation is the action of having the TPM sign some internal TPM data. Confidence in the attestation is related to the confidence in the key that is used to sign. The highest confidence is provided by a fixedTPM, restricted signing key that is created on a TPM with a certificate from the TPM manufacturer.
> — TPM 2.0 Library Part 1, Version 185, §28.1

> This parameter is not interpreted by the TPM and may contain any data chosen by the caller. The most common use of this parameter is expected to be as a nonce to ensure "freshness" of an attestation.
> — TPM 2.0 Library Part 1, Version 185, §28.4

> A key that is not restricted can sign any digest and would permit a forged attestation.
> — TPM 2.0 Library Part 3, Version 185, §18.1

> TPMU_HA is a union of all the hash algorithms implemented on a TPM.
> — TPM 2.0 Library Part 2, Version 185, §10.2.1

## 自研究との関係

（※ここは解釈）

### 1. SSH の exchange hash H はそのままでは `qualifyingData` に入らないことがある

これまでのノートでは「H はハッシュ値なので TPM の qualifying data に収まる」と書いてきたが、**Part 2 を読むと条件付きでしか成り立たない**。

- H の長さは KEX 方式名が定めるハッシュで決まる（[[rfc4253-ssh-transport-layer]] §8）。`-sha256` 系なら 32 オクテット、`-sha512` 系なら 64 オクテット
- `qualifyingData` の上限は「2 + **その TPM が実装する**最長ダイジェスト長」
- **SHA-512 を実装しない TPM では、64 オクテットの H は入らない**（上限 50 オクテット）

設計上の答えはおそらく、H をそのまま入れるのではなく **`qualifyingData = hashAlg || HASH(H ‖ 文脈)` の形に正規化する**こと。Part 1 §28.2 が「ダイジェストと method indicator の余地」と説明している形にそのまま合う。method indicator の中身は仕様の範囲外なので、本研究がここを定義することになる——**参照モデルからの delta として明示すべき箇所がまた 1 つ増えた**。

### 2. `TPMS_CLOCK_INFO` は問い 4 の「タイムスタンプ」に対する材料になる

nonce（`qualifyingData`）が「この接続のために作られた」ことを示すのに対し、`clockInfo` は「前回から何が起きたか」を示す。

- サーバがクライアントの AK ごとに前回の `resetCount` / `restartCount` / `clock` を覚えておけば、**前回のセッション以降にクライアントが再起動したか**が分かる。PCR は再起動でリセットされるので、再起動を検知したら Evidence を厳しめに評価し直す、というポリシーが書ける
- 難読化（§28.3）は**同じ鍵での差分を保つ**ので、この用途は妨げられない。サーバは毎回同じ AK を見るので問題ない
- ただし `clock` の原点は仕様の範囲外で、`TPM2_ClockSet()` で進められるので、**絶対時刻としては使えない**。単調性と差分だけを使うこと

### 3. プライバシー難読化は、本研究の構成では守りにならない

§28.3 の難読化は「異なる鍵で署名された attestation どうしを結びつけられないようにする」ためのもの。しかし本研究ではサーバが**同じ AK を毎回見る**ので、AK 自体がクライアント端末の識別子になる。[[rfc9683-riv-tpm-network-devices]] で指摘した「クライアント端末を Attester にするとプライバシー問題が出る」は、TPM 側の機構では解消されない。サーバごとに AK を分けるか、DAA（`TPM_ALG_ECDAA`、§28.5）を使うかの判断が要る。

### 4. 185 の変更が設計に直接効く点

- **SHA-1 は非推奨**（184）。Appraisal Policy では SHA-256 以上の PCR バンクを前提にすべき
- **`TPM2_CertifyX509()` は非推奨**（184）。AK の証明を X.509 で TPM に作らせる設計は採らず、`TPM2_Certify()` を使うのが仕様の推奨。[[ssh-tpm-ca-authority-device-attested-certs]] のような実装がどちらを使っているかは確認する価値がある
- **PQC**: ML-DSA 鍵は digest に直接署名しない（逐次署名か外部 μ）。`TPM2_Quote()` のように「TPM が内部でハッシュして署名する」コマンドで ML-DSA の制限付き鍵がどう扱われるかは今回確認できなかった（未解決に記載）。いずれにせよ ML-DSA の署名は ECDSA より桁違いに大きく、[[rfc4253-ssh-transport-layer]] §6.1 のパケット長制約に対して余裕が減る

### 5. 制限付き鍵であることの検証は Verifier の責務

`magic` による偽造防止は**制限付き鍵で署名されている場合にだけ**効く（Part 3 §18.1）。したがってサーバ（Verifier）は Quote の署名を検証するだけでは不十分で、**その AK が制限付き・`fixedTPM`・`sensitiveDataOrigin` であることを、AK の公開領域（`TPMT_PUBLIC` の属性）と、それを証明する証明書連鎖によって確認**しなければならない。これは [[draft-ietf-rats-reference-interaction-models]] §5 の Attester Identity / Evidence Authenticity の前提条件に対応し、SSH に載せる場合は「AK の公開領域と証明をどのメッセージで運ぶか」という設計項目になる。

## 未解決・気になる点

- **`TPM2_Quote()` を ML-DSA の制限付き鍵で使えるか**。Part 3 §18 の attestation 総論には ML-DSA への言及が見当たらなかった。Part 1 の署名方式選択の節と、Part 2 の `TPMT_SIG_SCHEME` の制約を精読すること
- **PC Client PTP v1.07 が Library 185 を要求するか**（検索結果の要約のみ。TCG サイトから PDF を取得できず未確認）。PC 向け TPM が必ず実装するハッシュアルゴリズムもこの文書が決めるので、上記「1.」の `qualifyingData` 上限の実際の値はここで確定する
- Version 185 の errata の有無と内容（検索結果に 2026-08 付の errata への言及があったが、TCG サイトから取得できず未確認）
- 参照実装の `V185` リリース時期。実装で `tpm2-tss` / `go-tpm` 等が 185 の新コマンドに追随しているかは別途確認
- AK の証明手順（`TPM2_MakeCredential()` / `TPM2_ActivateCredential()`、Part 3 と Part 1 §21 Credential Protection）は未読。SSH クライアントの AK をサーバに登録するフローを設計するときに必要
- Part 1 の PCR（Integrity Collection）とイベントシーケンスの節は未読
- TCG サイトの Cloudflare 対策により、**次回以降の `/collect` でも TCG の一次情報は直接取れない可能性が高い**。`docs/sources.md` に取得経路（Internet Archive の `id_` 付き URL）を追記するか検討
