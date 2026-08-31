---
id: "rfc:9334"
title: "Remote ATtestation procedureS (RATS) Architecture"
body: "IETF"
status: "Informational"
year: 2023
url: "https://www.rfc-editor.org/info/rfc9334"
type: spec
tags: [rats, remote-attestation, architecture, attester, verifier, relying-party, passport, background-check]
relevance: high
added: 2026-08-21
---

## 何を規定しているか

remote attestation の**アーキテクチャ**を定義する Informational RFC（2023-01）。著者は H. Birkholz, D. Thaler, M. Richardson, N. Smith, W. Pan。

具体的なプロトコルや暗号方式は規定せず、「一方の通信端点が他方の trustworthiness を検証する」ために必要な**役割・相互作用・概念メッセージ**を、プロセッサアーキテクチャ・Claim の内容・プロトコルのいずれに対しても中立な形で与える。

本フォルダの `docs/glossary.md` の役割語はすべてこの RFC に由来する。

## 本研究に効く定義・要件

### 役割（訳さずそのまま使う）

| 役割 | 本研究での対応物 |
|---|---|
| **Attester** | attestation される側の SSH ホスト（逆方向ならクライアント端末） |
| **Verifier** | Evidence を Appraisal Policy で評価する主体。SSH クライアント自身か、独立サービスか、CA 兼務か（＝中心的な問い 3） |
| **Relying Party** | 接続するか否かを決める SSH クライアント |
| **Endorser** | TPM ベンダ等。EK 証明書の発行元 |
| **Reference Value Provider** | OS ディストリビュータ、自組織のビルドシステム |

### 2 つのトポロジ

| モデル | 流れ | SSH に当てはめたときの含意 |
|---|---|---|
| **Background-Check Model** | Attester → Relying Party → Verifier → Relying Party | SSH クライアントが接続のたびに Verifier に問い合わせる。**Verifier の可用性が SSH 接続の前提になる**のが運用上の難点 |
| **Passport Model** | Attester → Verifier → Attester → Relying Party | ホストが事前に Attestation Result を取得して提示。ハンドシェイクが速いが、**Result の鮮度が落ちる**（中心的な問い 4） |

**この二択が SSH 統合における最初の設計判断になる。** SEAT の expat draft は両対応にしているが、SSH の運用実態（踏み台・大量ホスト・オフライン環境）を考えると片方に寄せる合理性があるかもしれない。

### 概念メッセージ

Evidence / Endorsements / Reference Values / Appraisal Policy / Attestation Result。SSH のどのメッセージにどれを載せるかが設計の中身になる。

## 拡張点・自由度

この RFC は意図的に「何を Claim にするか」「どう運ぶか」を規定しない。**SSH への統合はこの自由度の中で行う作業**であり、RFC 9334 自体と矛盾する余地はない。逆に言えば、RFC 9334 に準拠していることは主張の前提であって貢献ではない。

## 他仕様との関係

- 具体化: EAT (RFC 9711)、CMW (RFC 9999)、CoRIM (draft-ietf-rats-corim)、AR4SI (draft-ietf-rats-ar4si)
- 応用: RFC 9683 / 9684（ネットワーク機器の TPM 完全性検証・CHARRA）
- チャネルへの束縛: SEAT WG → [[seat-wg-charter]], [[draft-fossati-seat-expat]]

## 引用すべき箇所

> generating, conveying, and evaluating evidentiary Claims
> — RFC 9334, Abstract

> a model that is neutral toward processor architectures, the content of Claims, and protocols
> — RFC 9334, Abstract

（本文の §3 Architectural Overview、§5 Topological Patterns から、役割定義とトポロジ図の正確な引用を後で追加すること）

## 自研究との関係

（※ここは解釈）

**前提** — 本研究の Background 節で当然視して引く土台文献。用語をこの RFC に揃えることで、査読者に対して「標準的な枠組みの上で議論している」ことを示せる。

同時に注意すべきは、**RFC 9334 準拠は貢献にならない**という点。RATS は「SSH にどう載せるか」を何も言っていないので、貢献はその空白部分に置く必要がある。

論文での使い方: Background で役割語とトポロジを導入し、Design 節で「本研究は background-check / passport のどちらを採るか、なぜか」を論じる形が自然。

## 未解決・気になる点

- 本文をまだ通読していない。上記は abstract と既知の知識に基づく。**§5（トポロジ）と freshness の節は一次情報で精読すること**
- RFC 9334 が freshness についてどこまで踏み込んでいるか（nonce / epoch の扱い）
- Verifier が複数いる場合の扱いは RFC 9334 の範囲外か（draft-ietf-rats-multi-verifier が別途あるので範囲外と思われる）
