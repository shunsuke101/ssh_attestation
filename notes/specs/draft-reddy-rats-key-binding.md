---
id: "draft:reddy-rats-key-binding-02"
title: "Key Attestation for Entity Attestation Tokens (EAT)"
body: "IETF"
status: "Active Internet-Draft (individual submission, not IETF-endorsed)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-reddy-rats-key-binding/"
type: spec
tags: [rats, eat, key-attestation, cnf-claim, proof-of-possession, key-substitution-attack, eat-nonce, key-attributes, never-extractable, uccs, split-model]
relevance: high
added: 2026-10-13
---

> **本研究の中核にある問題——「クライアントの SSH 鍵の所持証明と、端末の attestation Evidence を、どう結びつけるか」——を正面から扱う文書。**
> **あわせて、[[rfc4253-ssh-transport-layer]] と [[tcg-tpm2-library-v185]] に書いた設計案（連結をハッシュして TPM の `qualifyingData` に入れる）を §8.3 が明示的に批判している。** 下の「自研究との関係」を参照。

## 何を規定しているか

EAT（RFC 9711）のプロファイルと新しい EAT claim を定義し、**ある鍵（Subject Key）の秘密鍵が、attestation された実行環境の中で生成・保護されていること**を暗号学的に示す仕組み。最新版 `-02`（2026-08-15）。

著者は T. Reddy (Nokia), H. Tschofenig (UniBw M.), T. Fossati (Linaro), I. Mihalcea (Arm), H. Birkholz (Fraunhofer SIT)。**RATS / SEAT の中心人物が揃っている**個人提出 I-D。

狙いは 1 文で言える:

> This mechanism addresses key substitution attacks that arise when attestation evidence and the certificate private keys are validated independently. — Abstract

## 本研究に効く定義・要件

### 構成（§4）

前提として **Subject Key は attested execution environment の中で生成・保持されていなければならない (MUST)**。これが key-attributes claim に権威を与える。

プロファイルが与える性質は 2 つ:

1. **Proof of Possession** — attestation を提示している主体が Subject Key の秘密鍵を支配していること
2. **Key-to-Platform Binding** — Subject Key の秘密鍵と、attestation された platform state の暗号学的な結びつき

組み合わせるのは次の 2 つだけ:

- **AK（Attestation Key）による EAT の署名**
- **周囲のプロトコルから得られる、Subject Key の protocol-level proof of possession**

### EAT Claims Set の中身（§4.2）

| claim | 内容 | 出典 |
|---|---|---|
| `eat_nonce` | **Verifier が与えた nonce** | RFC 9711 |
| `cnf` | **Subject Public Key** | RFC 8747 / RFC 7800 |
| `key-attributes` | Subject Key の保護属性と許容用途。**必須で、少なくとも 1 要素を含まねばならない (MUST)** | 本 draft が新設 |

`key-attributes` の属性値（`extractable` / `never-extractable` / `sensitive` / `local`）の意味は `draft-ietf-rats-pkix-key-attestation` に従う (MUST)。これにより Relying Party は「鍵は attested 環境内で生成されたものに限る」「秘密鍵の取り出しを禁じる」といったポリシーを強制できる。

### 検証手順（§4.2, §5.2）

Verifier が確認する関係は 3 つ:

1. **EAT の署名**が正当である（platform state が authentic である）
2. **protocol-level PoP** により Subject Key の秘密鍵の支配が示される
3. **`cnf` の公開鍵が、CSR または TLS エンドエンティティ証明書の公開鍵と一致する**（同じ運用鍵を指していること）

### PoP は周囲のプロトコルが担う（§5）

> In this profile, PoP MUST be verified by the surrounding protocol:
> * In certificate enrollment workflows, by validating the CSR signature.
> * In TLS workflows, by validating certificate-based TLS authentication. — §5

**PoP の機構を自分で定義せず、周囲のプロトコルに委ねている**のがこのプロファイルの設計。

### freshness（§5, §5.1）

- `eat_nonce` が**必須の freshness 機構**。Verifier が供給した単一の nonce 値を含まねばならない (MUST)
- nonce は **Verifier が供給し、予測不能で、Verifier の replay window 内で一意**でなければならない (MUST)
- **nonce は Relying Party が周囲のプロトコル経由で Attester に運ぶ**
- Verifier は EAT 内の nonce が自分が供給したものと一致することを検証しなければならない (MUST)
- EAT の時刻 claim（`iat` / `nbf` / `exp`）も検証しなければならない (MUST) が、**nonce の要求を置き換えるものではない**

> Failure to include verifier-provided freshness renders the mechanism vulnerable to replay of previously valid attestation evidence. — §5.1

### 脅威モデル（§8.1）と Key Substitution Attack（§8.5）

> This document addresses Key Substitution Attacks. In such attacks, valid attestation evidence from a protected execution environment is presented to a verifier while a private key used in certificate enrollment or TLS authentication is not generated or protected within that environment. — §8.1

§8.5 の具体例:

1. 攻撃者が TEE の外で秘密鍵 `K_bad` を生成する
2. 攻撃者は、TEE 内で保護された別の鍵 `K_good` についての正当な attestation evidence を持っている（あるいは入手する）
3. 攻撃者は `K_bad` で署名した CSR を提出し、そこに `K_good` の `cnf` を含む EAT を添える
4. 検証時、`cnf` の公開鍵（`K_good`）と CSR の公開鍵（`K_bad`）を比較する → 一致しないので束縛の検証が失敗する

> Although the attestation evidence and the CSR signature may each be valid independently, the mismatch prevents the establishment of a cryptographic binding between the certificate private key and the attested execution environment. — §8.5

### §8.3 — UCCS をハッシュして challenge に入れる構成への批判（重要）

本 draft は、代替構成を名指しで退けている:

> An alternative construction sometimes used in attestation protocols is to build an unsigned claims set (UCCS) containing the Subject Public Key and associated attributes, hash it, and supply the hash as a challenge to an existing attestation interface. In such constructions, the attestation evidence provides an indirect cryptographic binding between the claims set and the attested environment. **However, a TEE-bound process acting as a proxy could forward a fabricated UCCS on behalf of an untrusted caller, causing the attested environment to sign claims it did not generate and cannot verify.** — §8.3

そのうえで本 draft は **AK が EAT Claims Set を直接署名することを要求する**。理由は、鍵の保護属性は「その鍵を生成し保持している attested 環境」だけが直接の知識と権限を持つから（§8.3 冒頭）。

## 拡張点・自由度

- PoP の機構は周囲のプロトコルに委ねられている（§5）。**どのプロトコルでもよい**ので、SSH の `publickey` 認証をそこに当てられる
- nonce の運び方も「周囲のプロトコル経由」とされ、具体は規定されない（§5.1）
- §6 に **Split Model Profile**（Key Attestation Key = KAK を使う分離構成）がある。未読
- `key-attributes` の属性集合は `draft-ietf-rats-pkix-key-attestation` に委ねられている

## 他仕様との関係

- 土台: RFC 9711 (EAT)、RFC 8747 / RFC 7800 (`cnf` claim)、[[rfc9334-rats-architecture]]
- 参照: `draft-ietf-rats-pkix-key-attestation`（`key-attributes` の属性意味論。既読 `draft:ietf-rats-pkix-key-attestation-07`）、`draft-ietf-lamps-attestation-freshness`（証明書発行プロトコルでの nonce の入手と運搬）、`draft-ietf-rats-msg-wrap` 系
- 関連: [[draft-ietf-rats-reference-interaction-models]]（Handle = Verifier が出す nonce。-18 で Handle が Conceptual Message に昇格）
- 本研究の隣接: [[ssh-tpm-ca-authority-device-attested-certs]]（EK 照合だけで鍵と状態の束縛がない実装）、[[ssh-attest-proxy-sk-attestation-in-ssh-certs]]（証明書に attestation を載せるが freshness がない）

## 引用すべき箇所

> This mechanism addresses key substitution attacks that arise when attestation evidence and the certificate private keys are validated independently.
> — draft-reddy-rats-key-binding-02, Abstract

> In such attacks, valid attestation evidence from a protected execution environment is presented to a verifier while a private key used in certificate enrollment or TLS authentication is not generated or protected within that environment.
> — §8.1

> In this profile, PoP MUST be verified by the surrounding protocol
> — §5

> The nonce MUST be supplied by the verifier and MUST be unpredictable and unique within the verifier's replay window.
> — §5

> However, a TEE-bound process acting as a proxy could forward a fabricated UCCS on behalf of an untrusted caller, causing the attested environment to sign claims it did not generate and cannot verify.
> — §8.3

（※ `https://www.ietf.org/archive/id/draft-reddy-rats-key-binding-02.txt` の本文から取得。節番号は本文に付されているものをそのまま記載した）

## 自研究との関係

（※ここは解釈）

### 本研究の構造にそのまま当てはまる

`CLAUDE.md` の研究テーマは「server からの challenge で freshness を担保し、client からの response で client の完全性を server が保証する」である。このプロファイルを SSH に当てると次の対応になる:

| このプロファイル | 本研究での対応物 |
|---|---|
| Subject Key | **クライアントの SSH 認証鍵**（`publickey` 認証で使う鍵） |
| protocol-level PoP | **`publickey` 認証の署名**（[[rfc4252-ssh-authentication-protocol]] §7。session identifier を含む対象への署名） |
| `cnf` claim の Subject Public Key | クライアントが `SSH_MSG_USERAUTH_REQUEST` で提示する公開鍵 |
| `eat_nonce`（Verifier が供給） | **server からの challenge** |
| AK による EAT 署名 | TPM の AK による Evidence 署名 |
| `key-attributes`（`never-extractable` 等） | SSH 鍵が TPM 常駐で取り出せないことの主張 |
| 「周囲のプロトコル」 | **SSH そのもの** |

**「PoP は周囲のプロトコルが担う」という設計方針が、本研究にとって決定的に都合がよい。** SSH には既に `publickey` 認証という完成した PoP 機構があり、しかもそれは session identifier に束縛されている。本研究は PoP を再発明せず、attestation 側は「`cnf` に SSH 公開鍵を載せた Evidence を AK で署名する」だけでよい、ということになる。

### §8.5 の攻撃は本研究で現に起きる

SSH に置き換えるとこうなる:

1. 攻撃者が改竄したクライアント端末で、TPM の外に SSH 秘密鍵 `K_bad` を作る
2. 攻撃者は、正常な別端末（あるいは過去の自分）の TPM 内の鍵 `K_good` についての正当な Evidence を持っている
3. 攻撃者は `K_bad` で `publickey` 認証の署名を作り、`K_good` についての Evidence を添えてサーバーに送る
4. サーバーが署名と Evidence を**独立に**検証すると、両方とも正当なので通ってしまう

**つまり「`publickey` 認証を通し、かつ Evidence が affirming である」だけでは不十分で、attestation を足した意味が消える。** これは [[2026-sokolov-veraison-challenge-nonce-freshness-gap]] が指摘した「replay された quote が affirming になる」のと並ぶ、**設計で必ず潰さなければならない 2 つ目の穴**である。Sokolov の指摘は freshness（server challenge）で潰せるが、**key substitution は freshness では潰せない。鍵と Evidence の束縛が別途必要。**

したがって本研究の設計には **MUST が 2 つ**立つ:

1. Evidence は server の challenge を含むこと（freshness）
2. **Evidence はクライアントが `publickey` 認証に使う公開鍵を含み、サーバーは両者が一致することを検証すること**（key-to-platform binding）

**2 つ目は今まで本リポジトリのノートに明示的に書かれていなかった論点。** この draft の最大の収穫。

### §8.3 は以前のノートに書いた設計案への反論になっている

[[rfc4253-ssh-transport-layer]] と [[tcg-tpm2-library-v185]] に、次の形の案を書いた:

```
qualifyingData = HASH( server の challenge ‖ session identifier ‖ 文脈 )
```

これは §8.3 が批判する「claims set をハッシュして、既存の attestation インターフェースの challenge として渡す」構成そのものである。批判の中身は **「TEE 内のプロセスがプロキシとして、untrusted な呼び出し元に代わって捏造した UCCS を転送しうる。その結果、attested 環境は自分が生成しておらず検証もできない claim に署名してしまう」**。

**SSH / TPM の文脈でこの批判がどこまで当たるかは、慎重に見る必要がある。**

- 当たる部分: 改竄された SSH クライアントが、`qualifyingData` に入れる値を自由に作れるなら、TPM は「クライアントが言ってきた値」に盲目的に署名する。TPM は `qualifyingData` を一切解釈しない（[[tcg-tpm2-library-v185]] Part 1 §28.4 が明記）。つまり **TPM は「この公開鍵が TPM 内にある」とは言っていない**。言っているのは「指定 PCR の値がこれで、呼び出し元が渡した 32 バイトがこれ」だけ
- したがって、`qualifyingData` に SSH 公開鍵のハッシュを入れただけでは **「その SSH 鍵が TPM に保護されている」ことの証明にはならない**。改竄クライアントは TPM 外の `K_bad` のハッシュを入れて Quote を取れる
- **本来必要なのは `TPM2_Certify()`** ——TPM 内の鍵について、別の鍵（AK）で「この鍵は TPM 内にあり、属性はこれ」と証明させるコマンド。[[rfc9683-riv-tpm-network-devices]] のノートに「`TPM2_CertifyX509()` は非推奨、`TPM2_Certify()` を使うのが仕様の推奨」と書いたのが、ここで繋がる

**つまり本研究の設計は 2 つの TPM 操作を組み合わせる必要がある:**

| 目的 | TPM コマンド | 示せること |
|---|---|---|
| 端末の状態 + freshness | `TPM2_Quote()`（`qualifyingData` に server challenge） | 指定 PCR の値と、challenge への応答であること |
| SSH 鍵が TPM 内にあること | **`TPM2_Certify()`** | SSH 鍵が TPM 内に存在し、`fixedTPM` 等の属性を持つこと |

この 2 つと `publickey` 認証の署名（PoP）が揃って初めて、§8.3 の批判に耐える。**これは設計の具体像を一段進める発見であり、該当ノートに追記した。**

### 位置づけ

- [x] **前提** — 本研究の設計要件（鍵と Evidence の束縛）の出典として引く
- [x] **部品** — `cnf` + `key-attributes` + `eat_nonce` の構成をそのまま借用できる
- [ ] 競合 — SSH を扱っていないので競合ではない

`docs/scope.md` の「中心的な問い」との対応: **問い 4（freshness と束縛）に直接。問い 1 にも間接的に**（PoP を周囲のプロトコルに委ねられるので、認証層に載せる案と相性がよい）。

論文での使い方: Design 節で「鍵と platform state の束縛が必要な理由」を §8.5 の攻撃例を引いて示し、本研究の設計がその要件を満たすことを述べる。**IETF 側に既に同じ問題意識の文書があることは、提案の正当性を補強する。**

## 未解決・気になる点

- **§6 Split Model Profile（KAK を使う分離構成）が未読。** TPM では AK と SSH 鍵が別の鍵なので、**本研究はむしろ split model に近い可能性がある**。次に読むならここ
- §7.1–7.5（claim の具体的な構造、CBOR のエンコーディング、`purpose`）が未読。実装するなら必要
- §8.7 "Claim Omission and Downgrade"、§8.8 "Freshness and Replay Protection"、§8.9 "Scope of Guarantees" が未読。**§8.7 は本研究の段階的導入（問い 2）でダウングレード攻撃を論じるときに効くはず**
- このプロファイルは EAT（CBOR ベース）を前提にしている。**TPM の `TPMS_ATTEST` は EAT ではない。** TPM Quote を EAT に包む経路（CMW / `draft-ietf-rats-msg-wrap`、あるいは RFC 9999）を使うのか、EAT を使わず同じ構造を SSH 固有に定義するのかは設計判断になる
- `draft-ietf-lamps-attestation-freshness`（nonce の入手と運搬）が未取得。既読の `draft:ietf-lamps-csr-attestation` とは別文書
- 個人提出 I-D であり WG 採択されていない。**版の動きと RATS WG での議論状況を追うこと**（`rats@ietf.org` の ML は未巡回。`docs/sources.md` に巡回先として無いので追加を検討）
