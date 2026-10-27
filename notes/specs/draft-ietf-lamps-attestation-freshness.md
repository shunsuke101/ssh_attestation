---
id: "draft:ietf-lamps-attestation-freshness-09"
title: "Requesting a Freshness Nonce for Attestation Evidence in Certificate Signing Requests"
body: "IETF"
status: "Internet-Draft (LAMPS WG document, intended status Standards Track)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-ietf-lamps-attestation-freshness/"
type: spec
tags: [lamps, csr, attestation, freshness, nonce, background-check-model, cmp, est, cmc, session-binding, relying-party, rfc9684, tpm2-quote]
relevance: high
added: 2026-10-26
---

> 著者: Hannes Tschofenig, Hendrik Brockhaus (Siemens), Joe Mandel (AKAYLA), Sean Turner (sn3rd)。`-09` は 2026-10-17 付、2027-04-20 失効予定。`draft-tschofenig-lamps-nonce-cmp-est` を置き換えた WG 文書。
> 本ノートは datatracker の HTML 版（`https://datatracker.ietf.org/doc/html/draft-ietf-lamps-attestation-freshness-09`）を WebFetch で読んで書いた。フィールド名と節番号は原文で再確認すること。

## 何を規定しているか

CSR に attestation の Evidence を入れるとき（`draft-ietf-lamps-csr-attestation`）の freshness を担保するため、end entity が CSR の前に RA/CA から nonce を受け取る手順を定める。nonce の要求と応答を、CMP（`genm` / `genp`）、EST（`/nonce` エンドポイント）、CMC（Full PKI Request の制御）の 3 つに載せる。RATS の役割では RA/CA が Relying Party、end entity の中の部品が Attester で、Verifier は RA/CA の背後にいる。Figure 1 の題は "Message Flow in Background Check Model"。nonce を Evidence のどこに入れるかは attestation 技術に任せ、仕様自体は技術に依存しない。

## 本研究に効く定義・要件

| 節 | 内容 | どう使うか |
|---|---|---|
| §1 | RA/CA は Verifier と通信する Relying Party。nonce は RA/CA が自分で作っても Verifier から取ってもよい（§8） | 主テーマの問い 3（Verifier の配置）。SSH サーバーを Relying Party にし、Verifier を別に置く構成の先例 |
| §3 | 要求は `len`（8〜64 bytes、任意）と `reqTypeInfo`。応答は `nonce`（空なら freshness 不要）、`expiry`（秒、任意）、`respTypeInfo` | 主テーマの問い 4。SSH の server challenge のメッセージ設計の雛形 |
| §3 | nonce の要求と応答は、CSR と同じ PKI 管理操作の文脈で送るべき（SHOULD）。RA/CA は Evidence を opaque に扱うので、Evidence からどの nonce かを推定できないため | 問い 4 の「SSH セッションへの束縛」 |
| §4 / §5.1 / §5.2 / §6 | 束縛の手段。CMP は transaction ID（MUST）。EST は同じ (D)TLS セッションか cookie などのセッション維持機構（MUST）。EST-coaps は同じ DTLS 接続か Echo option。CMC は同じ transaction identifier（MUST）。対応付けられないときは CSR をその nonce に紐づけて扱ってはならない（MUST NOT） | Verifier / Relying Party の判定条件にそのまま採れる |
| §8 | nonce は 64 bit 以上のエントロピーを持つ（MUST）。RA/CA は一意性を保証し再利用しない（MUST）。nonce は Evidence の中に入れ、attestation payload の外の CSR 構造に置いてはならない（MUST NOT） | 両テーマの Verifier の判定条件 |
| §8 | nonce の状態保持による DoS への対策として、寿命の制限、未使用 nonce 数の上限、レート制限を行う（SHOULD） | SSH サーバーが challenge を保持するときの DoS 対策 |
| Appendix A | TPM 2.0 の例。RFC 9684 §2.1.1.3.2 の challenge-response を参照し、RFC 9684 の nonce-value は top-level の `nonce` に入れる。`respInfo` には PCR bank と index、使う AK の証明書名を入れる。`reqInfo` には使える AIK 証明書名とハッシュアルゴリズムを入れる。TPM Quote 自体は後で Evidence として運ぶ | 並行テーマ。RFC 9684 の challenge を別のプロトコルへ写した実例 |

## 拡張点・自由度

- `reqInfo` / `respInfo` の中身は定義せず、OID を付けて他の文書に任せる（§3.1）。
- nonce を Attester にどう渡すか、CSR に nonce がいくつ要るか、RA/CA と Verifier のどちらが nonce を作るかは対象外（§1）。
- attestation 形式が決定的な nonce 変換を定めている場合は、その変換だけを適用する（§8, §9）。
- 複数の `respInfo` が要るときは CMW で包む。composite Attester では lead Attester が sub-Attester に nonce を渡す（§3）。

## 他仕様との関係

- 参照している: `draft-ietf-lamps-csr-attestation`、RFC 9334（§10 freshness）、[[draft-ietf-rats-reference-interaction-models]]（§6 Generic Information Elements）、RFC 9684（Appendix A）、RFC 9711（EAT）、RFC 9783（PSA token）、RFC 9810（CMP）、RFC 9175（CoAP Echo）
- 参照されている: unknown
- 競合・重複する仕様: SEAT WG の attested TLS 系（[[seat-wg-charter]]）。こちらは freshness をハンドシェイクの中で得る

## 引用すべき箇所

> The nonce value MUST contain a random byte sequence with at least 64 bits of entropy.
> — §8

> The RA/CA MUST ensure that a nonce it generates is unique and MUST NOT be reused.
> — §8

> If the EST server cannot associate the CSR request with the prior nonce request and response messages [...] it MUST NOT treat the CSR as associated with the previously provided nonce.
> — §5.1（WebFetch が返した 2 断片を `[...]` でつないだ。原文で確認すること）

> acts as a Relying Party that communicates with one or more Verifiers
> — §1（RA/CA の役割）

## 自研究との関係

（※ここは解釈）

**主テーマと並行テーマの両方に効く。**

- **主テーマ**: 既存のプロトコル（CMP / EST / CMC）に「Relying Party が freshness 用の nonce を発行し、Attester に Evidence へ入れさせ、同じトランザクションに束縛する」手順を後付けした標準化の先例になる。SSH で server challenge を運ぶ設計（問い 1、問い 4）の直接の比較対象。SSH では束縛先として session identifier（鍵交換の exchange hash）があり、EST の「同じ TLS セッション」に当たる。「対応付けられなければ nonce を適用しない」という MUST NOT は、SSH サーバー側の判定条件としてそのまま使える。
- **主テーマとの違い**: LAMPS は証明書の発行時に 1 回だけ attestation する CA 兼務型で、attezt や `ssh-tpm-ca-authority`（[[ssh-tpm-ca-authority-device-attested-certs]]）と同じ型。本研究は接続ごとの challenge-response なので、nonce の寿命や DoS 対策の重みが違う。LAMPS は nonce の取得に専用の往復を足しているが、SSH ではユーザ認証のメッセージの中で challenge を返せる可能性がある。
- **並行テーマ**: Appendix A は RFC 9684 の challenge（nonce、PCR selection、AK の証明書名）を別のプロトコルへ写す例になっている。sysrepo plugin `rats-attester.so` の入力の作りと照らし合わせられる。

## 未解決・気になる点

- `expiry` の期限を過ぎて届いた CSR の扱いを、取得した範囲では規範的に定めていない。SSH で challenge の有効期限をどう扱うかの検討材料。
- IANA の EST 登録の配置案が 2 つ併記されたまま（編集者注）。コードポイントは TBD。
- §9 は replay 対策を EAT と PSA token の仕様に任せている。
- datatracker 上の WG state は表示されていなかった。ヘッダの intended status は Standards Track。
