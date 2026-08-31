---
id: "draft:fossati-seat-expat-03"
title: "Remote Attestation with Exported Authenticators"
body: "IETF"
status: "Active Internet-Draft (individual submission, not IETF-endorsed)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-fossati-seat-expat/"
type: spec
tags: [seat, tls, exported-authenticators, cmw, rats, post-handshake-auth, channel-binding]
relevance: high
added: 2026-08-21
---

## 何を規定しているか

通信する 2 者が **exported authenticators（RFC 9261）** を使って Evidence と Attestation Result を交換するための仕様。`cmw_attestation` という拡張を導入し、**post-handshake authentication の Certificate メッセージに attestation credential を載せる**。RATS の passport / background-check 両モデルに対応し、attestation を TLS コネクションに束縛する。

著者: Muhammad Usama Sardar, Thomas Fossati, Tirumaleswar Reddy.K, Yaron Sheffer, Hannes Tschofenig, Ionuț Mihalcea
最新版: `-03`（2026-07-04）

## 系譜（重要）

この文書は名前を 2 回変えている。追跡するときに取り違えやすい。

| 版 | 状態 |
|---|---|
| draft-fossati-tls-attestation（-10 まで） | **withdrawn**（本文中に "This draft has been withdrawn" と明記。datatracker 上は Active 表示のままなので注意） |
| draft-fossati-tls-exported-attestation（-02, 2025-07-03） | **Expired**。draft-fossati-seat-expat に置換 |
| **draft-fossati-seat-expat（-03, 2026-07-04）** | **現行**。SEAT WG 系列 |

つまり **TLS 1.3 ハンドシェイク自体を拡張する路線（tls-attestation）は放棄され、exported authenticators による post-handshake 路線に移った。** この方針転換の理由は本研究の設計判断に直接効くので、両者の差分を読む価値がある。

## 本研究に効く定義・要件

| 要素 | 内容 | どう使うか |
|---|---|---|
| `cmw_attestation` 拡張 | attestation credential を Certificate メッセージに入れる | SSH で言えば、ホスト鍵／SSH 証明書に相当する場所に Evidence を同梱する設計 |
| Exported Authenticators (RFC 9261) | ハンドシェイク後に追加の認証情報をやり取りする枠組み | **SSH には対応物が無い。** ここが移植の最大の障害 |
| passport / background-check 両対応 | どちらのトポロジでも使える | 中心的な問い 3（Verifier の配置）を仕様側で閉じずに実装に委ねる方針 |
| チャネルへの束縛 | attestation を TLS コネクションに束縛 | 中心的な問い 4（freshness / 再生防止）の解法そのもの |
| CMW (RFC 9999) | Evidence の包装形式 | SSH でも同じ包装を使えば Verifier 側を共通化できる可能性 |

## 拡張点・自由度

- attestation technology 非依存（TPM / TEE / DICE いずれでも）
- Evidence と Attestation Result のどちらを送るかはトポロジ次第

## 他仕様との関係

- 親: SEAT WG → [[seat-wg-charter]]
- 土台: RFC 9334 → [[rfc9334-rats-architecture]]
- 依存: RFC 9261 (Exported Authenticators), RFC 9999 (CMW), RFC 9711 (EAT)

## 引用すべき箇所

（一次情報の本文を通読して埋めること。現時点では datatracker の abstract 要約のみに基づく）

> a `cmw_attestation` extension allowing attestation credentials in Certificate messages during post-handshake authentication
> — draft-fossati-seat-expat-03, Abstract（要確認: 原文の正確な表現）

## 自研究との関係

（※ここは解釈）

**本研究にとって最も直接的な比較対象。** SSH 版を設計するとき、この draft の選択を一つずつ問い直す形で設計判断を組み立てられる。

| 判断 | expat（TLS） | SSH ではどうするか |
|---|---|---|
| 挿入位置 | post-handshake authentication | SSH には EA が無い。`ssh-userauth` の中か、`SSH_MSG_GLOBAL_REQUEST` か、KEX 拡張（RFC 8308 の ext-info）か |
| 運搬形式 | Certificate メッセージ内の `cmw_attestation` | SSH 証明書の `extensions` フィールドか、新規メッセージ型か |
| 束縛 | TLS コネクションに束縛 | SSH の session identifier（H）への束縛が自然な対応物 |
| トポロジ | passport / background-check 両対応 | 同じく両対応にすべきか、SSH の運用実態から片方に絞るか |

**「ハンドシェイク拡張路線を捨てて post-handshake に移った」という経緯は特に重要。** SSH でも KEX を直接いじる案は同じ理由で退けられる可能性が高い。その理由（実装負担？ ミドルボックス？ 版交渉の複雑さ？）を一次情報で確認したい。

## 未解決・気になる点

- **tls-attestation を withdraw した理由は何か。** draft 本文か SEAT/TLS の ML に記録があるはず。本研究の設計判断に直結するので最優先で確認
- SSH の session identifier への束縛は、EA のチャネル束縛と同等の強度を持つか
- `-03` の本文をまだ通読していない。上の表は abstract レベルの理解に留まる
