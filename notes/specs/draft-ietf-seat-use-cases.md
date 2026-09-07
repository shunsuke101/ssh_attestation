---
id: "draft:ietf-seat-use-cases-00"
title: "Security Goals and Use Cases for Integrating Remote Attestation with Secure Channel Protocols"
body: "IETF"
status: "Active Internet-Draft (SEAT WG Document)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-ietf-seat-use-cases/"
type: spec
tags: [seat, tls, dtls, rats, use-cases, channel-binding, freshness, requirements]
relevance: high
added: 2026-09-07
---

## 何を規定しているか

SEAT WG が **remote attestation を secure channel protocol に統合するときの security goals と use cases** を整理した文書。プロトコルそのものではなく、後続の仕様が満たすべき目標を先に固定するための要件文書。WG document（個人 submission ではない）として採択されている点が重要で、SEAT の公式な問題設定はこの文書が握る。

著者: unknown（一次情報の author 欄を未確認）
最新版: `-00`（2026-07-20）、14 ページ

## 本研究に効く定義・要件

この文書が挙げる 10 個の security goals は、`docs/scope.md` の「中心的な問い」とほぼ一対一で対応する。**SSH 版を設計するときの評価軸としてそのまま流用できる。**

| Security goal | 内容 | 本研究での対応物 |
|---|---|---|
| Cryptographic Binding to Communication Channel | Evidence をチャネルに暗号的に束縛 | 問い 4。SSH の session identifier `H` への束縛 |
| Compound Authentication | 鍵の所持証明と attestation を合成して 1 つの認証にする | 本研究の核。「鍵を持っている」＋「正しい状態である」 |
| Cryptographic Binding to Machine Identifier | Evidence を機器識別子に束縛 | SSH ホスト鍵 / IDevID との関係 |
| Attestation Credential Freshness | Evidence の鮮度保証 | 問い 4。nonce の運び方 |
| Negotiation and Capability Discovery | attestation 能力の交渉 | 問い 2。RFC 8308 `ext-info` が SSH 側の受け皿 |
| Attestation Model Flexibility | passport / background-check 両対応 | 問い 3（Verifier の配置） |
| Interaction with Peer Authentication | 既存のピア認証との関係 | SSH の hostkey 検証 / userauth との合成 |
| Runtime Attestation | 起動時だけでなく実行中の状態 | 長時間 SSH セッションでの再 attestation |
| Privacy Preservation | Evidence からの機器追跡を防ぐ | DAA 等 |
| Performance and Efficiency | 検証コストとレイテンシ | 問い 5 |

Use cases は 10 件。うち本研究に近いのは **High-Assurance Command Execution**、**Securing Control and Management Planes**、**Operation-Triggered Attestation for High-Impact Application Operations** の 3 件。いずれも「特権的な操作を実行する前に相手の状態を確かめたい」という筋で、**これはまさに SSH のユースケース**にもかかわらず SSH は名指しされていない（下記）。

## 拡張点・自由度

- security goals は「何を満たすべきか」だけを述べ、達成手段を規定しない。SSH 固有の手段（`H` への束縛、`ext-info` での交渉）を当てはめる余地がそのまま残っている。

## 他仕様との関係

- 親: SEAT WG → [[seat-wg-charter]]
- 土台: RFC 9334 → [[rfc9334-rats-architecture]]
- 姉妹文書: [[draft-many-seat-architecture]]（アーキテクチャ）、[[draft-usama-seat-intra-vs-post]]（タイミング分類）
- 具体化: [[draft-fossati-seat-expat]]、[[draft-reddy-seat-expat-transport]]

## 引用すべき箇所

> The initial focus is on TLS 1.3 and its datagram-oriented variant, DTLS 1.3.
> — draft-ietf-seat-use-cases-00

## 自研究との関係

（※ここは解釈）

**この文書の最大の価値は、書かれていることではなく書かれていないことにある。**

SSH / Secure Shell への言及が本文中に **一箇所も無い**（2026-09-07 に一次情報を検索して確認）。スコープは TLS 1.3 と DTLS 1.3 に明示的に限定されている。一方で use case として挙がる "High-Assurance Command Execution" と "Securing Control and Management Planes" は、実運用ではまさに SSH が担っている領域である。

つまり **「attestation を secure channel に統合する」ことを標準化している当の WG が、管理平面の事実上の標準プロトコルである SSH を対象外にしている**。これは本研究の Introduction で提示できるギャップとして相当強い。従来の「SSH は TOFU だから弱い」という動機づけに加えて、「標準化側もまだ手を付けていない」という位置づけが取れる。

ただし論文で主張する前に **確認すべきこと**: この除外が (a) 意図的なスコープ判断なのか、(b) 単に誰も提案していないだけなのか。SEAT の ML を 2026-09-07 に見た範囲では議論は TLS 1.3 に集中しており SSH の話題は出ていないが、40 通のサンプルに過ぎない。WG 憲章（[[seat-wg-charter]]）の scope 記述と突き合わせる必要がある。

`docs/scope.md` の中心的な問いのうち **1, 2, 3, 4, 5 すべて**に、評価軸という形で間接的に答えている。

## 未解決・気になる点

- 著者一覧を未取得。datatracker の author 欄で確認すること
- 憲章上 SSH は明示的に排除されているのか、単に未着手なのか
- 10 個の security goals のうち、SSH に移したときに**達成が TLS より難しくなるもの**はどれか。Exported Authenticators の非存在（[[draft-fossati-seat-expat]] 参照）が効いてくるのは Runtime Attestation と Compound Authentication だと予想するが未検証
- use case 10 件それぞれの本文をまだ読んでいない。上の 3 件選別は見出しレベルの判断
