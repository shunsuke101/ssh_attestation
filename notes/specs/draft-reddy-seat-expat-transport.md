---
id: "draft:reddy-seat-expat-transport-02"
title: "Application-Layer Transport for Exported Authenticators and Attestation"
body: "IETF"
status: "Active Internet-Draft (individual submission, not IETF-endorsed)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-reddy-seat-expat-transport/"
type: spec
tags: [seat, altea, exported-authenticators, post-handshake, transport, negotiation, re-attestation]
relevance: high
added: 2026-09-07
---

## 何を規定しているか

**ALTEA**（Application-Layer Transport for Exported Authenticators）。Exported Authenticator メッセージ（RFC 9261）を TLS 上で 2 者間でやり取りするための、**バイナリのアプリケーション層トランスポートプロトコル**。TLS 自体を変更せずに post-handshake authentication を実現する。

著者: Tirumaleswar Reddy (Nokia), Hannes Tschofenig (University of the Bundeswehr Munich)
最新版: `-02`（2026-08-25）、24 ページ

## 本研究に効く定義・要件

### 2 つの binding

| モード | 運び方 |
|---|---|
| **HTTP binding** | Extended CONNECT を使い、HTTP コネクション上の Capsule としてメッセージを運ぶ。HTTP/2 と HTTP/3 に対応 |
| **Shim mode** | HTTP を介さず TLS / DTLS 1.3 の直上で動作。frame ベースの区切りと magic cookie `0xE5A7A19C` を使う |

### 解こうとしている問題

RFC 9261 は Exported Authenticator の**仕組み**を定義したが、**それをいつどう送るかのシグナリングをアプリケーションプロトコル側に丸投げしていた**。ALTEA はその欠けている層を埋める。提供するもの:

- attestation model と encoding format の**双方向の capability negotiation**
- 長寿命コネクション上での **re-attestation**（HTTP binding）
- Exported Authenticator 一般に使える汎用性（attestation 専用ではない）
- ID による request / response の対応づけ

in-handshake attestation との対比: in-handshake はネゴシエーション段階で一度行われるだけで、**再接続なしには繰り返せない**。

## 拡張点・自由度

- shim mode の存在が示すとおり、**HTTP は必須ではない**。「secure channel の直上に薄いフレーミング層を置いて EA を運ぶ」という構造が本質。
- capability negotiation の中身（attestation model, encoding format）はトランスポート非依存。

## 他仕様との関係

- 親: SEAT WG → [[seat-wg-charter]]
- 依存: RFC 9261 (Exported Authenticators)
- 姉妹: [[draft-fossati-seat-expat]]（EA に attestation を載せる方）に対し、こちらは**その EA を運ぶ土管**
- アーキテクチャ: [[draft-many-seat-architecture]]
- タイミング論: [[draft-usama-seat-intra-vs-post]]（post-handshake 路線の具体化）

## 引用すべき箇所

> a binary, application-layer transport protocol for exchanging Exported Authenticator messages between two peers over TLS
> — draft-reddy-seat-expat-transport-02, Abstract

## 自研究との関係

（※ここは解釈）

**中心的な問い 1（どのレイヤで運ぶか）に対する、TLS 側の最新の答え。そして SSH との構造的な差が最も鮮明に出る文書でもある。**

TLS 陣営がたどった道筋はこう整理できる:

1. ハンドシェイクを拡張する（`draft-fossati-tls-attestation`）→ **withdrawn**
2. post-handshake の EA に載せる（[[draft-fossati-seat-expat]]）
3. しかし EA を運ぶシグナリングが無い → **アプリ層に専用トランスポートを新設**（本文書）

つまり TLS は「プロトコル本体をいじらない」代償として、**アプリケーション層に新しい土管を一本引く**ことを選んだ。

**ここで SSH は有利かもしれない。** SSH には最初から多重化されたチャネル機構（RFC 4254）と `SSH_MSG_GLOBAL_REQUEST` があり、**ALTEA が TLS のために新設しているものを既に持っている**。ALTEA の shim mode（secure channel 直上の薄いフレーミング層）に対応するものが、SSH では既存の connection protocol でそのまま賄える可能性がある。

| ALTEA の要素 | SSH の既存対応物 |
|---|---|
| shim mode のフレーミング | SSH connection protocol のチャネル（RFC 4254） |
| capability negotiation | RFC 8308 `ext-info` → [[iana-ssh-registry-and-extension-points]] |
| re-attestation on long-lived connections | 既存チャネル上で追加メッセージを送るだけ |
| request / response 対応づけ | `SSH_MSG_GLOBAL_REQUEST` の `want_reply` |

**これは本研究の主張として使える**: 「attestation の secure channel 統合は TLS では新規トランスポートの発明を要したが、SSH では既存の拡張点の組み合わせで足りる」。もし本当にそう書けるなら、SSH を選ぶ積極的な理由になる。ただし今は表面的な対応づけに過ぎず、**ALTEA の本文を精読して各要素が本当に等価かを検証する必要がある**。

`docs/scope.md` の中心的な問い **1（レイヤ）・2（後方互換性）・5（長時間セッションでの再検証コスト）** に効く。

- [x] **競合** — 同じ問題（EA/Evidence の運搬）を TLS 上で解いている。SSH 版との差分を明示する必要あり
- [x] **部品** — capability negotiation の設計は借用できる

## 未解決・気になる点

- **magic cookie `0xE5A7A19C` を使う shim mode の設計理由**。既存トラフィックとの識別のためだと思われるが、SSH では不要になるはず（チャネル型名で区別できる）。この差が「SSH の方が素直」という主張の裏付けになるか確認する
- re-attestation が HTTP binding のみとされている理由。shim mode で再 attestation ができないなら、SSH への移植で何が問題になるか
- capability negotiation で交渉する「attestation model」の具体的な値。RFC 8308 `ext-info` の拡張名として登録するときの設計に直結する
- ALTEA と [[draft-fossati-seat-expat]] の役割分担が本文レベルで明確か。両方読んで重複を確認すること
