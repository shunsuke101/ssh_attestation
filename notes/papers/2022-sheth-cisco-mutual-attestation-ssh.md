---
id: "url:https://patents.google.com/patent/US11321465B2/en"
title: "Network security by integrating mutual attestation"
authors: ["Sujal Sheth", "Shwetha Subray Bhandari", "Eric Voit", "William F. Sulzen", "Frank Brockners"]
year: 2022
venue: "US Patent 11,321,465 B2 (Cisco Technology, Inc.)"
url: "https://patents.google.com/patent/US11321465B2/en"
doi: null
type: paper
tags: [patent, cisco, ssh, tls, ipsec, mutual-attestation, client-attestation, nonce, bloom-filter, tpm, prior-art, eric-voit, us11934525]
relevance: high
added: 2026-10-26
---

> **継続出願 US 11934525 B2（`url:https://patents.google.com/patent/US11934525B2/en`）も本ノートで扱う。** 型と `id` の扱いは [[2021-sheth-cisco-attestation-peering-ssh]] と同じで、特許だが `paper` にしている。
> 2026-10-19 に `high` で登録したが、10-19 と 10-26 午前は WebFetch の権限拒否で一次情報を読めなかった。2026-10-26 午後の再実行で、Google Patents の HTML から明細書の SSH の節とクレームを読めた。

## 概要

SSH、TLS、SSL、IPsec のような暗号プロトコルのセッション確立中に、相手の完全性データを TPM の署名付きで受け取って信頼レベルを判定し、プロトコルの次の段階に進むかを決める方式。Cisco 名義で、発明者は US 11165861 と同じ 5 名。

| | US 11321465 B2 | US 11934525 B2 |
|---|---|---|
| 出願番号 | US16/752,488 | US17/712,499（継続出願） |
| 出願日 | 2020-01-24 | 2022-04-04 |
| 優先日 | 2019-04-04 | 2019-04-04 |
| 登録日 | 2022-05-03 | 2024-03-19 |
| 状態（Google Patents の表示） | Expired - Fee Related | Active |

公開番号は US20200320199A1 と US20220222347A1。優先権の基礎は US 62/829,570（2019-04-04）、62/830,181 と 62/830,178（2019-04-05）。Google Patents は US 11934525 の調整後の満了日を 2040-01-24 と表示しているが、法的な結論ではないと注記している。

## 手法・貢献

- 脅威モデル: 侵害された相手とセッションを確立してしまうこと（取得できた明細書の範囲から読んだもの）
- 前提とする信頼点: TPM などの crypto-processor。US 11934525 のクレーム 1 は、TPM の内部カウンタの状態と reference database による proof of freshness の検証を含む
- Evidence として明細書が挙げるもの: measured-boot stamp（例: PCR 0–7 の SHA1 ハッシュ）、プロセスごとのソフトウェア版のチェックサム、TPM の measurement validation token（nonce ではなく TPM のカウンタに依存）、trusted storage 上のログ、CPU や NPU などハードウェア部品の完全性
- 評価方法: 特許なので評価はない

### SSH 実施例（FIG. 5A, "SSH Attestation"）

主な流れは US 11165861 と同じく、SSH サーバーが server credentials に加えて自分の完全性データを送り、クライアントが続行か拒否かを決めるもの。そのうえで、この特許の明細書には次の記述がある。

- KEXINIT に完全性データを添えれば man-in-the-middle 攻撃を防げる可能性がある
- `SSH_MSG_USERAUTH_REQUEST`（509）に完全性データを添えられる
- 完全性データを定期的に運ぶ新しいメッセージ `SSH_MSG_CS` を定義できる
- **SSH サーバーがクライアントの完全性データを検証し、接続と認証の続行を許すかを決められる**
- 役割は逆にもできる

SSH の節には nonce、challenge、TPM Quote、freshness の記述が見当たらなかった（取得できた範囲）。freshness のための challenge は総論の節にある。

### クレーム

US 11321465 B2 のクレーム 1（WebFetch が返した連続断片をつないだもの）:

> A computer-implemented method, comprising: sending, via a server and using a cryptographic security protocol, a message associated with establishing an encrypted network session; receiving one or more responses from a set of client devices, the one or more responses comprising random numbers, each response containing one or more random numbers from a perspective of the server, wherein the one or more random numbers form a set of random numbers, wherein the set of random numbers is algorithmically combined into a single nonce, wherein the single nonce is passed through a crypto-processor to generate a signature which at least includes the single nonce and information from the crypto-processor which allows a determination of a level of trust of the set of client devices, wherein the information from the crypto-processor comprises integrity data associated with the set of client devices, the integrity data comprising at least one of information about a secure boot, a log of software changes made on the set of client devices, one or more software-version checksums for one or more processes, proof that the set of client devices supports trusted storage for received data, and an integrity of one or more hardware components; identifying a level of trust of each of the set of client devices based on the one or more responses; and determining whether to perform a next step in the cryptographic security protocol based on the level of trust, wherein the cryptographic security protocol comprises at least one of a Secure Shell (SSH) protocol, a Transport Layer Security (TLS) protocol, a Secure Sockets Layer (SSL) protocol, and an Internet Protocol Security (IPsec) protocol.

従属クレーム 9 はサーバーが完全性データを出せないときのセッション終了、従属クレーム 10 は乱数の集合を Bloom filter で 1 つの nonce にまとめること。

US 11934525 B2 の独立クレーム 19（同じく断片をつないだもの）:

> A non-transitory computer-readable storage medium containing instructions that, when executed by one or more processors, cause the one or more processors to: obtain, from one or more computing devices, one or more messages comprising a nonce; generate a signature comprising the nonce and integrity data from the processor; identify a level of trust of each of the one or more computing devices based on the signature; and determine whether to perform a next step in a cryptographic security protocol based on the level of trust.

US 11934525 B2 のクレーム 1 と 10 は、これに proof of freshness の検証（TPM の内部カウンタと reference database による）を加え、プロトコルを "a Secure Shell (SSH) protocol, a Transport Layer Security [...] Secure Sockets Layer (SSL) protocol, and an Internet Protocol Security (IPsec) protocol" に限定している（`[...]` は抽出で欠けた部分）。

## 自研究との関係

（※ここは自分の解釈）

**主テーマに効く。**

- [ ] **前提**
- [x] **競合** — 「SSH のセッション確立中に、サーバーがクライアントの完全性を判定して続行するかを決める」という本研究の中心の構図を、明細書が書き、クレームも SSH を名指ししている
- [ ] **部品**
- [x] **背景** — Introduction で「産業界の先行技術」として触れる必要がある

`docs/scope.md` の「中心的な問い」との対応:

- **問い 1（どのレイヤに載せるか）**: 明細書は KEXINIT への添付、USERAUTH_REQUEST への添付、新メッセージ `SSH_MSG_CS` の 3 案を挙げる。本研究の候補とほぼ重なるので、レイヤの選び方そのものでは新規性を主張しにくい。
- **問い 4（freshness）**: US 11321465 のクレーム 1 は、クライアント側の乱数を集めて 1 つの nonce にまとめる。server challenge で freshness を取る本研究とは、nonce の出どころが逆に読める。ただし、クレームの文は「誰の crypto-processor が署名するか」が曖昧で、読み方は要確認。US 11934525 は TPM の内部カウンタで freshness を検証する。
- **差分の候補**: RATS の Challenge/Response モデル（RFC 9334、[[draft-ietf-rats-reference-interaction-models]]）に沿った Evidence と判定条件の明確化、SSH の session identifier への束縛（明細書の SSH の節には束縛の記述がない）、OpenSSH 上の実装と評価、端末を Attester にするときのプライバシー。
- **知財上の注意**: US 11321465 は失効と表示されているが、継続出願の US 11934525 は有効と表示され、独立クレーム 19 はプロトコルを限定しない広い書き方になっている。権利範囲の判断は専門家に確認すること。ここでの読みは法的な評価ではない。

## 引用すべき箇所

> the SSH server 502 can validate the integrity data of the SSH client 501 and decides on whether the SSH client 501 is allowed to connect to the network and proceed with authentication and/or continue to be connected to the network.
> — US 11321465 B2, FIG. 5A の説明（"SSH Attestation"）

> a new set of SSH messages can be defined, such as, for example, SSH_MSG_CS messages 520A, 520B which can carry integrity data between the two protocol parties at regular intervals.
> — 同上

> The integrity data may be attached to any SSH messages from the SSH client 501 and/or the SSH server 502
> — 同上

> Note that the above described roles could also be reversed.
> — 同上

## 未解決・気になる点

- 要約の全文は取得できていない（冒頭の "Technologies for attestation techniques, systems, and methods to confirm the integrity of a device" のみ）。
- US 11934525 のクレーム 1 は抽出で一部が欠けた。PDF で確認が要る。
- US 11321465 のクレーム 1 の「crypto-processor」が誰のものか。
- 被引用文献: Huawei の US 12706760 B2 "Communication method integrated with trustworthiness measurement and apparatus"（IKE / IPsec のセッション確立に trustworthiness measurement を組み込む。2026-10-26 に `medium` で登録）。
- Google Patents の類似文献のうち未調査のもの: US 11956273 B2 "Discovering trustworthy devices using attestation and mutual attestation"、US 11784808 B2 "Authentication of network devices using access control protocols"、US 2020/0322334 A1 "Authentication of network devices based on extensible access control protocols"。
- US 11165861 ファミリーの継続出願 4 件（US 11570242 / 11652874 / 11882176 / 12363191）は依然未確認。
