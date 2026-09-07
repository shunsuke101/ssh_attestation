---
id: "draft:usama-seat-intra-vs-post-04"
title: "Pre-, Intra- and Post-handshake Attestation"
body: "IETF"
status: "Active Internet-Draft (individual submission, not IETF-endorsed)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-usama-seat-intra-vs-post/"
type: spec
tags: [seat, tls, attestation-timing, freshness, replay, channel-binding, latency]
relevance: high
added: 2026-09-07
---

## 何を規定しているか

Evidence を **いつ生成・署名するか**によって attestation を pre- / intra- / post-handshake の 3 つに分類し、それぞれの利点と限界を整理した文書。プロトコル規定ではなく分類と trade-off の記録で、SEAT WG 内の議論の合意状況を残す目的を持つ。

著者: M. U. Sardar (TU Dresden)
最新版: `-04`（2026-07-06）、21 ページ

## 本研究に効く定義・要件

まず時刻の定義を 3 つ置く。この定義が議論全体の土台になる。

| 用語 | 定義（原文） |
|---|---|
| Evidence Generation Time | "Time when Evidence is generated (more specifically when Claims are signed)" |
| Connection Establishment Time | "Time at which TLS handshake is performed" |
| Lifetime of Connection | "Time period starting from Connection Establishment Time until the connection exists" |

その上で 3 分類と trade-off:

| 分類 | 定義 | 利点 | 限界 |
|---|---|---|---|
| **Pre-handshake** | ハンドシェイク前に Claims を署名 | TLS の変更不要。キャッシュ可能でスケールする | **replay / diversion 攻撃に脆弱**。接続時点の状態を保証できない |
| **Intra-handshake** | ハンドシェイク内で Claims を署名 | 追加ラウンドトリップ不要。Evidence Generation Time と Connection Establishment Time が一致 | **ハンドシェイクレイテンシが大きい（Evidence 生成だけで 140–1020 ms）**。diversion / relay 攻撃に脆弱。TLS への侵襲的変更が必要。使えるクレームが限られる |
| **Post-handshake** | 接続確立後、接続の生存期間中に署名 | 標準のハンドシェイクレイテンシのまま。接続期間を通じた状態をカバー。**TLS の変更が不要**。実装と形式検証が容易 | アプリケーション層の変更が必要 |

## 拡張点・自由度

- 分類は TLS を前提に書かれているが、**「Claims の署名時刻」と「チャネル確立時刻」の関係という軸自体はトランスポート非依存**。SSH にそのまま持ち込める。

## 他仕様との関係

- 親: SEAT WG → [[seat-wg-charter]]
- 姉妹: [[draft-many-seat-architecture]] は intra / post の 2 分類を採用（pre を落としている）
- post-handshake 路線の具体化: [[draft-fossati-seat-expat]]、[[draft-reddy-seat-expat-transport]]
- 要件側: [[draft-ietf-seat-use-cases]]

## 引用すべき箇所

> Remote attestation provides guarantees about the state of Attester **only** at the time at which signing of Claims is done.
> — draft-usama-seat-intra-vs-post-04

## 自研究との関係

（※ここは解釈）

**中心的な問い 1（どのレイヤで運ぶか）と問い 4（freshness）に、そのまま使える分析枠組みを与えてくれる文書。** 本研究の設計判断の章は、この 3 分類を SSH に読み替えるところから始めるのが素直だと思う。

SSH に対応させると:

| 分類 | SSH での対応位置 | 見込み |
|---|---|---|
| Pre-handshake | ホスト鍵や SSH 証明書の `extensions` に Evidence を事前に埋め込む | 実装は最も楽。だが replay に弱く「接続時点の状態」を示せないので、TOFU 置換という本研究の動機を満たさない可能性が高い |
| Intra-handshake | KEX の拡張、または RFC 8308 `ext-info` を使った鍵交換中の交換 | Evidence 生成に 140–1020 ms かかるという数字が本当なら、**SSH のハンドシェイクに載せるのは相当苦しい**。SSH は対話用途でレイテンシに敏感 |
| Post-handshake | `ssh-userauth` 内、または `SSH_MSG_GLOBAL_REQUEST` / 新規チャネル | TLS 側と同じ理由で最有力。ただし SSH には Exported Authenticators に相当する既製の枠組みが無い（[[draft-fossati-seat-expat]]） |

**特に効くのがレイテンシの実測値**。intra-handshake で 140–1020 ms という数字は、TLS 側が post-handshake に舵を切った理由の定量的裏付けであり、本研究が「SSH でも KEX 拡張路線を採らない」と判断する根拠として引用できる。[[draft-fossati-seat-expat]] の「なぜ tls-attestation が withdraw されたか」という宿題に、この文書が部分的に答えている。

一方で **SSH ならではの反論もある**: SSH の接続はセッションが長く、接続頻度は TLS より桁違いに低い。数百 ms のハンドシェイク増加が TLS ほど致命的でない可能性がある。ここは本研究の独自の主張になりうるので、`intra-handshake は SSH では許容できる` という線も捨てずに検討したい。

- [x] **前提** — 分類枠組みを土台として使う
- [x] **背景** — Introduction でタイミング選択の難しさを示すのに使う

## 未解決・気になる点

- 140–1020 ms という測定の**条件**（TPM か TEE か、どのハードウェアか、クレーム数）を本文で確認する。数字だけ引用すると危険
- "diversion attack" の定義がこの文書独自のものか SEAT 共通用語か。ML の "Evidence relay and substitution attack" スレッド（2026-08-29 / 08-31）と同じ攻撃を指している可能性がある
- pre-handshake を [[draft-many-seat-architecture]] が落とした理由。この文書は 3 分類、アーキテクチャ文書は 2 分類で食い違っている
- SSH のセッション長・接続頻度の実態データが必要。「SSH ならレイテンシを許容できる」を主張するなら実測がいる
