---
id: "draft:ietf-rats-reference-interaction-models-17"
title: "Reference Interaction Models for Remote Attestation Procedures"
body: "IETF"
status: "Active Internet-Draft (RATS WG Document, In WG Last Call)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-ietf-rats-reference-interaction-models/"
type: spec
tags: [rats, interaction-models, challenge-response, uni-directional, streaming, freshness, handle, attestation-nonce, epoch-marker, passport, background-check, charra, mutual-authentication]
relevance: high
added: 2026-09-09
---

## 何を規定しているか

RATS（RFC 9334）の役割の間で Conceptual Message、とりわけ Evidence を**どう運ぶか**の相互作用モデルを 3 つ定義する Internet-Draft。**Challenge/Response**、**Uni-Directional**、**Streaming Remote Attestation** の 3 つ。

著者は H. Birkholz, M. Eckel（Fraunhofer SIT）, W. Pan（Huawei）, E. Voit（Cisco）。最新版 `-17`（2026-04-02 提出、2026-10-04 失効予定）、Intended status は **Standards Track**、RATS WG で **In WG Last Call**。`draft-birkholz-rats-reference-interaction-model` を置き換えたもの。

文書自身が述べる目的は 2 つ (§1)。他文書がモデル記述をコピペして少しずつズレていくのを防ぐこと、そして各仕様が「参照モデルからの delta をどこに置いたか」を明示できるようにすること。つまり**他の仕様が引くための土台**として書かれている。

## 本研究に効く定義・要件

### Handle という抽象（§6）

3 モデルを貫く中心概念。**Handle** = recentness / freshness / 再生防止のために外部から Attester に与えられ、Evidence に含められる情報要素。nonce も Epoch Marker も Handle の一種として括られる。

> All interaction models have a strong focus on the use of a Handle to incorporate a proof of freshness and to prevent replay attacks. **The way the Handle is processed is the most prominent difference between the three interaction models.** — §7

つまり **3 モデルの選択 ≒ freshness の設計そのもの**。問い 4 はこの文書の中に枠組みごと入っている。

### nonce の語の切り分け（§2.2）

`-17` の時点で「nonce」を 3 つに切り分ける節が置かれている。

| 種別 | 説明 |
|---|---|
| **Attestation nonce (freshness handle)** | Attesting Environment に渡され Evidence に暗号的に束縛される。本文書で「nonce」といえばこれ |
| **TLS nonce** | TLS ハンドシェイクと鍵導出で使う乱数。「Handle ではなく、本文書の Evidence freshness の意味論とは無関係」と明記 |
| **Signature nonce** | ECDSA 等が内部で使う一時乱数。プロトコルから見えず、要求される性質（一意性・秘匿性）が異なる |

### 情報要素（§6）

| 必須 | 任意 |
|---|---|
| `handle` / `claims` / `collectedClaims` / `evidence` / `attestationResult` / `verInputs` | `attEnvIDs` / `eventLogs` / `claimSelection` |

SSH のどのメッセージに何を載せるかを考えるときの**部品表**としてそのまま使える。`claimSelection` が省略された場合は Attester の全 Claim を使わなければならない (MUST)、という既定も決まっている。

### Essential Requirements（§4）— SSH に効く

Evidence の適切な伝達には Integrity と Authentication が MUST。このうち Authentication の充たし方が 2 つ示されている:

1. Evidence に署名する（explicit authentication）——伝達のための追加のハンドシェイクを要さない
2. **認証を提供する secure channel の上で Evidence を運ぶ**

**2 番目が本研究の論拠になる。** SSH は認証済み secure channel を最初から持っている。§4 は「そこに載せてよい」と明示的に言っている。

### Normative Prerequisites（§5）

- **Authentication Secret**: RATS の相互作用が始まる前に確立され、Attester の Attesting Environment だけが使えること (MUST)
- **Attester Identity**: Endorser による「区別可能性」の表明。明示的（Claim / Endorsement）でも暗黙的（trust anchor に合う署名）でもよい。**distinguishability は uniqueness を含意しない**——グループ署名や DAA credential でもよい
- **Attestation Evidence Authenticity**: Verifier が検証鍵材料と trust anchor を得られること (MUST)。手段は provisioning / Evidence と同送 / 安定した参照の 3 択で、具体的な配布・登録機構は範囲外
- **Evidence Freshness**: Verifier が理解できる freshness の指標を Evidence が含むこと (MUST)

### 3 つのモデル（§7）

| モデル | Handle の出所 | SSH に載せたときの姿（※解釈） |
|---|---|---|
| **Challenge/Response** §7.1 | Verifier（配備によっては Relying Party）が推測困難な nonce を生成し `requestEvidence(handle, ?attEnvIDs, ?claimSelection)` で渡す | サーバーが nonce を送り、クライアントが TPM Quote を返す。往復が 1 回増える。SSH のハンドシェイクに最も素直に載る |
| **Uni-Directional** §7.2 | 外部の TTP である **Handle Distributor**（RFC 3161 の TSA 相当）が署名付き時刻を配る。TUDA が例 | 事前に得た Evidence を接続時に一方的に提示。往復は増えないが TTP の常設が要る |
| **Streaming** §7.3 | subscribe 時に Verifier が生成。broker（pub/sub）経由と直接（observer）の 2 形態 | 単発の SSH 接続とは相性が悪いが、**長時間セッション中の再検証**には使える可能性 |

### RFC 9334 のトポロジとの関係（§7.1.1）— 重要

**Passport と Background-Check は Challenge/Response の 2 つの変種として整理されている。** RFC 9334 だけを読んでいると「トポロジ」と「相互作用モデル」が別軸に見えるが、この文書では前者が後者の下位分類になっている。

どちらのモデルでも **Handle は Relying Party が生成してもよい (MAY)**（Verifier が生成して Relying Party 経由で渡してもよい）と書かれている。本研究のように **Verifier と Relying Party が同じ SSH サーバーに同居する**構成では、この区別は消える。それが仕様逸脱にならないことは §2.1 が保証している——Verifier と Relying Party が同一エンティティに載る場合も "Remote" Attestation と呼んでよい、と明記されている。

### Handle のライフサイクル（§7.2.1）

Uni-Directional 固有の問題として、新旧の Handle が同時に流通する **"grey zone"** が論じられている。対策は Handle Expiry / 定期的な同期チェック / Grace Period の 3 つ。delta Evidence については「値が一度変わって元に戻った場合も、両方の遷移を報告しなければならない (MUST)」という強い要求がある。

### Mutual Authentication（§9.4.2）— 論文で突ける空白

Challenge/Response では双方向に機微情報が流れるため相互認証が重要、として実現手段の例を 2 つ挙げる: **mTLS** と、**サーバー認証 TLS + HTTP 認証**。

**SSH は挙げられていない。** SSH は公開鍵による相互認証を標準で持つのに、RATS 側の参照文書には選択肢として存在しない。本研究の位置づけを説明する材料になる。

## 拡張点・自由度

- **Handle の生成方法と rotation のルールは範囲外**（配備・プロトコル依存と明記）
- identity establishment、鍵の配布・登録、時刻同期、証明書失効は範囲外 (§3)
- Attestation Result を受けた remediation / recovery も範囲外 (§3)
- Evidence 以外の Conceptual Message（Endorsement、Attestation Result 等）への適用は「できるが本文書の対象外」
- **「網羅的なリストではない」と明言している** (§3)。新しいモデルを出す余地はあるが、まず 3 モデルからの差分として書くのが作法

## 他仕様との関係

- 参照している: RFC 9334、RFC 9711 (EAT)、RFC 9783 (PSA TF-M)、RFC 9781、RFC 5280、RFC 3161 (TSA)、`draft-ietf-rats-epoch-markers`、`draft-birkholz-rats-tuda`、`draft-ietf-spice-sd-cwt`
- 参照されている: [[rfc9683-riv-tpm-network-devices]] §3.2 が本 draft §7.1 から challenge-response の参照モデルを導出。逆に本 draft §9 は「TPM ベースなら RFC 9683 §5 も見よ」と返す
- 土台: [[rfc9334-rats-architecture]]（役割語と Conceptual Message はすべてこちら）
- 実装 (§8): **CHARRA** — Fraunhofer SIT による prototype。<https://github.com/fraunhofer-sit/charra>。CoAP (RFC 7252) + CBOR、TPM 2.0 と tpm2-tss 依存、BSD 3-Clause。Appendix A に CoAP FETCH body の CDDL がある

## 引用すべき箇所

> All interaction models have a strong focus on the use of a Handle to incorporate a proof of freshness and to prevent replay attacks. The way the Handle is processed is the most prominent difference between the three interaction models.
> — draft-ietf-rats-reference-interaction-models-17, §7

> Alternatively, Evidence can be conveyed over a secure channel that provides authentication
> — §4 (Authentication)

> The interaction models described in this document are meant to serve as a solid foundation and reference for other solution documents within or outside the IETF. Solution documents of any kind can refer to these interaction models to prevent duplicating text and to avoid the risk of subtle discrepancies. Similarly, deviations from the generic model described in this document can be illustrated in solution documents to highlight distinct contributions.
> — §3

> This conveyance can also be "Local", if the Verifier role is part of the same entity as the Attester role [...] or the Verifier and Relying Party roles are hosted by the same entity
> — §2.1

## 自研究との関係

（※ここは解釈）

**問い 4（freshness をどう保証するか）の答えは、この 3 モデルのどれを採るかとほぼ同値になる。** §7 が「Handle の処理の仕方こそが 3 モデルの最大の違い」と言っている以上、モデル選択と freshness 設計は分離できない。逆に言えば、本研究は「モデルを選ぶ」という形で問い 4 に答えられる。

**SSH には Challenge/Response が素直に載る。** 接続確立は本質的に request/response であり、サーバーが nonce を出す＝ Verifier が nonce を出す、という canonical な形とそのまま一致する。しかも SSH には既に「サーバー側が寄与した値をクライアントが署名する」構造がある（鍵交換の exchange hash、publickey 認証で署名対象にセッション ID が入る）。attestation nonce をここに結びつけられれば、Evidence を SSH セッションに束縛できる。

ただし §2.2 の切り分けには注意が要る。あの節は**用語の整理**であって「SSH／TLS の乱数を attestation の freshness に流用してはいけない」と禁じているわけではない。とはいえ「TLS nonce は Handle ではない」と明記された以上、**セッション由来の値をそのまま attestation nonce として使う設計は、なぜ Handle の要件を満たすのかを別途論証しなければ通らない**。ここは本研究の設計判断が要る箇所であり、参照モデルからの delta として明示すべき点でもある。

**Uni-Directional は SSH の運用実態と噛み合いにくい。** Handle Distributor という TTP を常設し、Attester と Verifier の双方に時刻を配る必要がある。踏み台越しやオフライン環境を含む SSH の配備で TSA を前提にできるかは疑わしい。ただし問い 4 に「タイムスタンプ」が加わった以上、TUDA 系は一度きちんと見ておくべき。

**論文での位置づけ方**: §3 が「参照モデルからの deviation を書けば、それが distinct contribution として示せる」と自ら述べている。本研究は「Challenge/Response モデルを SSH のトランスポート層／認証層に埋め込んだ変種」として位置づけ、canonical なモデルとの差分（Verifier と Relying Party の同居、nonce のセッション束縛、往復回数の制約）を明示する形が、査読者にも IETF にも通りやすい。

**§9.4.2 の空白**は小さいが効く。相互認証の実現手段として mTLS しか挙がっていないところに SSH を置けるなら、それ自体が「なぜ SSH なのか」の答えの一部になる。

## 未解決・気になる点

- **版の動き**: `-17`（2026-04-02）で WG Last Call、Doc Shepherd Follow-up 中、マイルストーンは 2026-04。**RFC 化されれば ID が `rfc:XXXX` に変わる。次回 `/collect` で必ず確認すること**（RFC 化されたら seen.jsonl に新レコードを追記し、本ノートの frontmatter に両方の ID を書く）
- §2.2 の nonce 切り分け節、§7.2.1 の Handle ライフサイクル節、§9.2〜9.4 のセキュリティ考察が**どの版で入ったか未確認**。WG Last Call 直前に整理された可能性があり、そうならこれらは「まだ議論が動いている箇所」ということになる
- §7.3 Streaming（broker あり／なし、4 つの図）は図中心にざっと見ただけ。**長時間 SSH セッション中の継続 attestation に使えるか**は要精読
- Appendix A の CDDL（CoAP FETCH body の例）は未読。SSH メッセージの設計例として参考になるか
- 引用した §4 の "secure channel that provides authentication" が参照する RFC 9781 §3〜4 を未確認。SSH がこの条件を満たすと言えるかの根拠がそこにある可能性
