---
id: arxiv:2609.09668
title: "Session Attestation for Unmodified TLS Services in Confidential Virtual Machines"
authors: ["Qi Gu", "Sheng Ma"]
year: 2026
venue: "preprint (arXiv)"
url: "https://arxiv.org/abs/2609.09668"
doi: 10.48550/arXiv.2609.09668
type: paper
tags: [attested-tls, confidential-vm, ephemeral-key-binding, backward-compatibility, os-level-interposition, csv]
relevance: high
added: 2026-09-14
---

## 概要

Confidential VM 上で動く**既存サービスを一切改変せずに** session attestation を成立させる SessionLatch の提案。アプリケーションバイナリ・TLS スタック・企業の既存証明書の 3 つをそのまま残したまま、OS 層に置いた observer が ServerHello に現れる **server の ephemeral ECDHE 公開鍵 Y** を観測し、その束縛値を attestation report に署名させる。クライアント側は OS に latch（一時的なパケットフィルタ）を入れ、Evidence の検証が済むまで自分の暗号化レコードの送信を止める。検証が通れば latch は自分を外し、以降は素の TLS データパスに戻る。Hygon CSV 上の Linux / Windows 実装で、短い upload の平均レイテンシが TNG 比で 63.1% / 23.0% 改善。

## 手法・貢献

- **束縛の作り方**: observer が CVM 内で TLS endpoint が ephemeral 鍵を生成する瞬間を捉え、`B_S = H(δ_S ∥ ks_S)`（`ks_S` は選択された group と server 公開鍵 Y）を作る。これを attestation report に載せる: `E_S = Quote(M_S, P_S, B_S)`。クライアントは受信した ServerHello から同じ `B_S` を**独立に再計算**して照合する。TLS の秘密（master secret 等）には一切触れない。
- **Evidence を運ぶ経路**: アプリの TLS コネクションとは**別の control connection**。ClientHello が観測された時点で latch が control request を投げるので、Evidence のやり取りが TLS ハンドシェイクと時間的に重なる。これがレイテンシ削減の主因。
- **役割分担**: 「元の TLS スタックが service authentication と key confirmation の責任を持ち続ける」。証明書チェーン・ドメイン名・CertificateVerify・Finished の検証は標準どおり TLS スタックが行い、attestation は**その上に重ねるだけ**。
- 実装: Linux は netfilter NFQUEUE、Windows は WinDivert。
- 脅威モデル: 攻撃者は外部ネットワーク・ホスト・ハイパーバイザ・プロキシを支配し、観測・改竄・破棄・再生・中継ができる。さらに**ハンドシェイク前に対象サービスの長期 TLS 秘密鍵を入手済み**でもよい、という強い設定。信頼するのは承認済み CVM のカーネル・TLS endpoint・attestation コンポーネントと、クライアント側の verifier と latch。
- 評価: Hygon CSV CVM（OpenEuler 22.03 SP4 + OpenSSL）。Native TLS 1.3 / TLS+RA / TNG / SessionLatch を比較。1 KiB upload で 5.510 ms（TLS+RA 5.879 ms、TNG 14.942 ms）。64 MiB の実効スループットは Native の約 89%（Linux）/ 97%（Windows）。

## 自研究との関係

（※ここは自分の解釈）

- [ ] **前提** — 自分が土台として使う
- [x] **競合** — 同じ問題を別の方法で解いている（差分を明示する必要あり）
- [x] **部品** — 一部を借用できる
- [ ] **背景** — Introduction の文脈づけに使う

`docs/scope.md` の「中心的な問い」との対応:

- **問い 2（後方互換性・段階的導入）** — 本命。「プロトコルを一切変えない」という最も過激な後方互換の取り方の実例。SSH でこれをやるなら、sshd も ssh クライアントも触らずに OS 層で KEXDH_REPLY を観測して host key と ephemeral 鍵を Evidence に束縛する、という対応物が作れる。**自分の設計が「OpenSSH に手を入れる」路線を採るなら、なぜ OS 層の interposition ではだめなのかを説明する責任が生じる**。ここが Related Work での差分の要点になる。
- **問い 4（Freshness とセッション束縛）** — 束縛対象を **ephemeral 公開鍵**に取っているのが要点。`2026-sardar-identity-crisis-attested-tls.md` が指摘した diversion attack は、まさにこの束縛の欠如が原因だった。SSH でいえば束縛対象の候補は (a) session identifier H、(b) KEX の server ephemeral 公開鍵、(c) host key。SessionLatch は (b) を選んでいる。SSH では H が (b) と host key の両方を含むハッシュなので、**H を束縛すれば (b) より強い**という議論ができるはず。ここは自分で詰める価値がある。
- **問い 5（検証コストとレイテンシ）** — Evidence のやり取りをハンドシェイクと**重ねる**ことでレイテンシを隠す、という手口はそのまま SSH に持ち込める。SSH の場合 KEXINIT から NEWKEYS までの間に余裕があるので、同じことができる可能性が高い。評価の比較対象の立て方（Native / naive RA / 既存手法 / 提案）もそのまま参考になる。

借用できそうな部品: 束縛値の作り方 `B_S = H(δ_S ∥ ks_S)` の形、および「verifier が承認するまで**クライアント側の送信を止める**」という gating の考え方（SSH なら NEWKEYS 後・SERVICE_REQUEST 前で止めるのが自然か）。

## 引用すべき箇所

> a trusted observation of the server's locally generated ephemeral public key, combined with standard TLS key confirmation — abstract

> While evidence is pending, the latch holds client encrypted records after ClientHello.

> Once ClientHello appears, the latch extracts L and immediately sends a control request. Request propagation therefore overlaps the application TLS handshake.

> Side channels, compromise of an approved TCB, incorrect admission policies, denial of service, and intentional disclosure by an approved application are outside the protocol's guarantees.

（※ arXiv の HTML 版 `https://arxiv.org/html/2609.09668v1` から取得。**節番号・ページ番号は未確認。** 引用時に補うこと。PDF 直取りはバイナリが読めず失敗した）

## 未解決・気になる点

- **査読前の preprint**（2026-09-08 投稿）。採録先が決まったら DOI 付きの新 ID で再登録し、このノートを指すこと。
- mutual attestation モードは「サーバ側で未承認クライアントからのデータを止める」部分がプロトタイプに含まれておらず、**評価されたのはクライアント送信の gating のみ**と明記されている。自研究で双方向を主張するならここは埋められていない穴として指摘できる。
- Hygon CSV 固有の実装。TPM ベースの platform attestation に読み替えたとき、Quote に任意の 64 バイトを載せられる TPM2_Quote の qualifyingData で同じ束縛ができるか（できるはずだが）を確認する。
- OS 層 interposition なので、**OS 自体の完全性は前提**になっている。SSH で measured boot からの完全性を主張したい自研究とは信頼の出発点が違う。この差は明示する。
- latch が「自分を外す」設計は性能上は美しいが、**セッション途中での再検証（SSH の rekey に相当）ができなくなる**はず。SSH は rekey があるので、ここは自分の設計で差を出せる箇所かもしれない。
