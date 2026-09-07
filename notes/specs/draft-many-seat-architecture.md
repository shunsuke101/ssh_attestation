---
id: "draft:many-seat-architecture-00"
title: "Secure Evidence and Attestation Transport (SEAT) Architecture"
body: "IETF"
status: "Active Internet-Draft (individual submission, not IETF-endorsed)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-many-seat-architecture/"
type: spec
tags: [seat, architecture, rats, channel-binding, session-binding, attestation-timing, tls]
relevance: high
added: 2026-09-07
---

## 何を規定しているか

RATS（RFC 9334）と secure channel establishment protocol を合成するための**アーキテクチャ枠組み**。用語を定め、RATS のロールをトランスポートのエンドポイントに対応づけ、Evidence 配送のタイミングパターンを示し、Evidence をコネクションに束縛する条件を規定する。SEAT 系文書群の中で**構造を定義する位置**にある。

著者: N. Ritz, T. Fossati, T. Reddy, I. Mihalcea
最新版: `-00`（2026-07-04）、22 ページ

## 本研究に効く定義・要件

### RATS ロールのエンドポイント対応

| RATS ロール | SEAT での位置づけ |
|---|---|
| Attester | 自身の状態について Evidence を生成するネットワークエンドポイント |
| Relying Party | Attestation Result を認可判断に使うエンドポイント |
| Verifier | Evidence を appraise して Attestation Result を出す主体 |

### 束縛（binding）の 3 条件

**この節が本研究にとって一番重要。** Evidence をセッションに束縛する手続きを 3 段階に分解している。

1. セッション固有の **binding value** を確立する
2. エンドポイントごとに **directional binder** を導出する
3. attesting environment がその binder を **Evidence のペイロードに署名で焼き込む**

これにより **replay across sessions（セッションをまたいだ再生）と endpoint substitution（エンドポイントのすり替え）を防ぐ**。

### タイミングモデル

Intra-Handshake Attestation と Post-Handshake Attestation の 2 つ。[[draft-usama-seat-intra-vs-post]] の 3 分類から pre-handshake が落ちている（理由は未確認）。

## 拡張点・自由度

- 本文は主に TLS を念頭に書かれているが、**適用対象を "secure channel establishment protocols" 一般としている**。TLS 以外の具体的な instantiation は本文に無い。
- 束縛の 3 条件は「binding value をどう作るか」を規定しない。つまり **SSH の session identifier `H` を binding value に据える instantiation は、このアーキテクチャの枠内で書ける**。

## 他仕様との関係

- 親: SEAT WG → [[seat-wg-charter]]
- 土台: RFC 9334 → [[rfc9334-rats-architecture]]
- 要件: [[draft-ietf-seat-use-cases]]
- タイミング分類の詳細: [[draft-usama-seat-intra-vs-post]]
- 具体化: [[draft-fossati-seat-expat]]、[[draft-reddy-seat-expat-transport]]

## 引用すべき箇所

> an architectural framework for composing Remote ATtestation procedureS (RATS) with Secure Evidence and Attestation Transport (SEAT)
> — draft-many-seat-architecture-00, Abstract

> secure channel establishment protocols
> — draft-many-seat-architecture-00（TLS 以外への適用可能性を明示する箇所。原文の正確な文脈は要確認）

## 自研究との関係

（※ここは解釈）

**本研究を「新しい提案」ではなく「既存アーキテクチャの SSH instantiation」として位置づけられる可能性を開く文書。** これは論文の売り方として大きい。ゼロから設計したと主張するより、IETF が定めつつある枠組みに SSH を当てはめた最初の仕事だと言う方が、査読でも標準化コミュニティでも通りやすい。

束縛の 3 条件を SSH に当てはめると:

| 条件 | SSH での実現 | 検討事項 |
|---|---|---|
| session-specific binding value | 鍵交換で得られる **session identifier `H`** | `H` は RFC 4253 で定義され、セッション一意。素直な候補 |
| directional binder | クライアント側・サーバ側で別の値を導出 | SSH は既に `H` から方向別の鍵を導出している（RFC 4253 §7.2 の `A`–`F`）。**同じ導出パターンを流用できる** |
| binder を Evidence に署名で焼き込む | TPM quote の nonce フィールドに binder を入れる | 問い 4 の解法がここで閉じる |

**第 2 条件（directional binder）に SSH の既存機構が綺麗に対応する**のは収穫。TLS 側で新規に定義している導出を、SSH では RFC 4253 の既存の鍵導出と同じ構成で書けるなら、後方互換性（問い 2）の議論も楽になる。

`docs/scope.md` の中心的な問い **1（どのレイヤか）・3（Verifier の配置）・4（freshness）** に直接効く。

## 未解決・気になる点

- **pre-handshake を落とした理由**。[[draft-usama-seat-intra-vs-post]] は 3 分類、こちらは 2 分類。どちらかが古いのか、意図的な絞り込みか
- "directional binder" の具体的な導出方法。本文の該当節を精読すること。SSH の `A`–`F` 導出と本当に同型かはまだ印象レベル
- 個人 submission（`draft-many-`）であり WG document ではない。[[draft-ietf-seat-use-cases]] が WG 採択されているのと対照的で、**アーキテクチャ側はまだ WG 合意に達していない**可能性がある。採択状況を追うこと
- SSH の `H` を binding value にする案は、**KEX 完了後でないと使えない**。したがって intra-handshake attestation とは相性が悪い。この制約は SSH 固有で、TLS 側の議論には現れていない論点になりうる
