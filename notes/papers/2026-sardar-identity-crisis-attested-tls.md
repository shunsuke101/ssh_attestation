---
id: doi:10.1145/3779208.3785387
title: "Identity Crisis in Confidential Computing: Formal Analysis of Attested TLS"
authors: ["Muhammad Usama Sardar", "Mariam Moustafa", "Tuomas Aura"]
year: 2026
venue: "Proceedings of the 21st ACM ASIA Conference on Computer and Communications Security (AsiaCCS '26)"
url: "https://doi.org/10.1145/3779208.3785387"
doi: 10.1145/3779208.3785387
type: paper
tags: [attested-tls, formal-verification, proverif, diversion-attack, channel-binding, freshness, compound-authentication]
relevance: high
added: 2026-09-14
---

## 概要

secure channel protocol に remote attestation を合成した「attested TLS」を、ProVerif 2.05 による記号的検証で形式解析した論文。標準化候補の 2 方式 —— Intel の Interoperable RA-TLS（pre-handshake attestation）と `draft-fossati-tls-attestation`（intra-handshake attestation）—— を同一のテンプレート上でモデル化し、security goal ごとに成否を比較した。結果、両方式とも **server identity / server authentication / compound authentication を満たさない**ことが示され、さらに IRA-TLS は Evidence freshness も破れる。攻撃は diversion attack と呼ばれ、同一の measurement を持つ別マシンへクライアントを黙って誘導できる。

## 手法・貢献

- **貢献の中心は「比較のためのテンプレート」**。attested TLS 系プロトコルを並べて評価するための security goal の集合（Evidence Integrity / Evidence Freshness / Attestation Key Secrecy / Server Identity / Server Authentication / Compound Authentication）を定義し、その上で 2 方式を検証した。
- 著者の公開リポジトリ `CCC-Attestation/formal-spec-id-crisis` に ProVerif のモデルと結果表が置かれている。結果表の要約:

| Property | IRA-TLS | TLS-a (`draft-fossati-tls-attestation`) |
|---|---|---|
| Evidence Integrity | ○ | ○ |
| Evidence Freshness | **×** | ○ |
| Attestation Key Secrecy | ○ | ○ |
| Server Identity | **×** | **×** |
| Server Authentication | **×** | **×** |
| Compound Authentication | **×** | **×** |

- 脅威モデル: Dolev-Yao 型のネットワーク攻撃者。加えて攻撃者は**正規の measurement を通す TCB を自分でも動かせる**（同じソフトウェアを走らせた別マシンを用意できる）。
- 前提とする信頼点: attestation key と TCB の measurement。これらが正しくても identity が定まらない、というのが主張の核。
- 評価方法: ProVerif 2.05 による記号的検証（計算量的証明ではない）。

## 自研究との関係

（※ここは自分の解釈）

- [x] **前提** — 自分が土台として使う（引用して当然視できる）
- [x] **競合** — 同じ問題を別の方法で解いている（差分を明示する必要あり）
- [ ] **部品** — 一部を借用できる
- [x] **背景** — Introduction の文脈づけに使う

`docs/scope.md` の「中心的な問い」との対応:

- **問い 1（どのレイヤで Evidence を運ぶか）** — pre-handshake と intra-handshake の両方を同じ物差しで測った結果、**どちらも同じ欠陥を持つ**と出ている。つまりレイヤ選択だけでは compound authentication は得られない、というのがこの論文から引ける最重要の示唆。SSH で鍵交換層に置くかユーザ認証層に置くかを議論する際、「層を選べば解決する」という書き方はできない。
- **問い 4（Freshness とセッション束縛）** — diversion attack は「Evidence は本物・新鮮だが、それを提示しているのが目の前の相手とは限らない」という形の攻撃であり、Evidence と**チャネルの鍵素材**の束縛が欠けていることに起因する。自分の設計では Evidence に SSH の session identifier（RFC 4253 の H、最初の鍵交換のハッシュ）を必ず含める、という要件の根拠としてここを引く。
- すでに `state/seen.jsonl` に `draft:fossati-tls-attestation-10` を medium で登録してあるが、**その方式が形式的に破られている**という事実はノート化されていなかった。`notes/specs/draft-fossati-seat-expat.md` からもこのノートを参照すべき。

自研究との差分の立て方: この論文は TLS を対象にした**攻撃・検証側**の仕事であって、SSH に対する設計提案ではない。自分の貢献は「SSH という別プロトコルで、この論文が定義した goal を最初から満たす設計を出す」ことに置ける。逆に言えば、**自分の設計を出したら同じ 6 つの goal で自己評価することが期待される**。

## 引用すべき箇所

> Intel's RA-TLS/Interoperable RA-TLS is vulnerable to replay attacks

> the composition of TLS with remote attestation is known as attested TLS protocol

（※ DOI ページ（ACM DL）は 403 で取得できなかったため、上記は著者公開リポジトリ `CCC-Attestation/formal-spec-id-crisis` の README および著者による RATS interim 2025 の発表資料に基づく。**ページ番号付きの正確な引用は本文 PDF を入手してから補うこと。**）

## 未解決・気になる点

- 論文が提案する mitigation の具体的な中身を一次情報で確認できていない。README とスライドからは「identity の定義を明確化し、Evidence をチャネルに束縛する」方向であることは読めるが、**具体的にどの値を束縛せよと言っているか**は本文を当たる必要がある。AsiaCCS の proceedings か著者版 PDF を入手すること。
- DisCoTec 2025 の ICE ワークショップに先行版（"Identity Crisis in Attested TLS for Confidential Computing"）がある。**同一物の別版**なので、そちらを別 ID で登録する場合はこのノートを指すこと。
- ProVerif による記号的検証なので、計算量的な安全性は対象外。この限界は自分が引用するときにも明示する。
- compound authentication という語の定義がこの論文の鍵。RFC 9334 の語彙には無い概念なので、自分の論文で使うならこの論文の定義を引く形にする。
