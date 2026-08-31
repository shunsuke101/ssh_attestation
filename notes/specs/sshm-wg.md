---
id: "url:https://datatracker.ietf.org/group/sshm/about"
title: "Secure Shell Maintenance (SSHM) Working Group"
body: "IETF"
status: "Active Working Group"
year: unknown
url: "https://datatracker.ietf.org/group/sshm/about/"
type: spec
tags: [sshm, ietf, ssh, standardization, working-group, hostkey-update, ssh-cert]
relevance: high
added: 2026-08-21
---

## 何を規定しているか

**SSH は現在も IETF で能動的に保守・拡張されている。** その担い手が SSHM（Secure Shell Maintenance）Working Group。憲章上の主目標は「maintain the Secure Shell (SSH) protocol」で、初期の目的は (1) 現行実装を反映するよう SSH の RFC 群を更新すること、(2) SSH が使う暗号アルゴリズム一覧を維持すること。

憲章の価値観として「strong security, simplicity, and ease of implementation」を挙げる。

マイルストーンは 2024-12〜2025-07 に集中しており、既存機能の文書化ドラフトの採択呼びかけが並ぶ（sntrup761-x25519、chacha20-poly1305、SSH Agent Protocol、rfc9519bis）。

## 現在の成果物

### 公開済み RFC

| RFC | タイトル | 種別 | 時期 |
|---|---|---|---|
| **9987** | Secure Shell (SSH) Agent Protocol | Proposed Standard | 2026-05 |
| **9941** | SSH Key Exchange Method Using Hybrid Streamlined NTRU Prime sntrup761 and X25519 with SHA-512 | Informational | 2026-04 |

### 現行 Internet-Draft

| Draft | タイトル | 状態 | 本研究との距離 |
|---|---|---|---|
| **draft-ietf-sshm-hostkey-update-00** | **Host key update mechanism for SSH** | WG Document | **最も近い。ホスト鍵の信頼をどう更新するかを扱う** → [[ssh-core-rfcs]] |
| **draft-ietf-sshm-cert-01** | SSH Certificate Format | WG Document | 近い。Evidence の運搬先候補 → [[draft-ietf-sshm-cert]] |
| draft-ietf-sshm-strict-kex-02 | SSH Strict KEX extension | WG Document | Terrapin 対策。KEX を触る前例 |
| draft-ietf-sshm-mlkem-hybrid-kex-10 | PQ/T Hybrid Key Exchange with ML-KEM in SSH | RFC Editor Queue | PQC |
| draft-ietf-sshm-chacha20-poly1305-04 | Secure Shell (SSH) authenticated encryption cipher: chacha20-poly1305 | In WG Last Call | 暗号 |
| draft-ietf-sshm-composite-sigs-00 | Post-Quantum Composite Signatures in SSH | New WG Document | PQC |

## 本研究に効く事実

**憲章は attestation、hardware security、host key trust、TOFU のいずれにも言及していない。**

現在の作業は (1) 既存実装の後追い文書化、(2) 暗号アルゴリズムの更新、(3) PQC 対応 に集中しており、**信頼モデルそのものを変える議論は行われていない。**

## 他仕様との関係

- 保守対象: RFC 4250–4254 → [[ssh-core-rfcs]]
- 拡張の受け皿: IANA レジストリと RFC 8308/9519 → [[iana-ssh-registry-and-extension-points]]
- 対比: [[seat-wg-charter]]（attestation を扱うが TLS 限定）

## 自研究との関係

（※ここは解釈）

### 位置づけが完全に定まる

前回の `/collect` で見つけた SEAT WG と合わせると、IETF の現状はこう整理できる:

| WG | attestation | 対象プロトコル | 結果 |
|---|---|---|---|
| **SEAT** | **扱う** | (D)TLS 1.3 のみ | SSH は対象外 |
| **SSHM** | **扱わない** | SSH | 信頼モデルは触らない |
| **RATS** | 扱う（アーキテクチャ） | プロトコル中立 | 具体的な載せ方は規定しない |

**この 3 つの隙間がちょうど本研究の位置。** 「SSH に attestation」は、どの WG の現在の作業項目にも入っていない。しかも隣接する 2 つの WG が同時に活動しているので、「誰も必要と思っていないから空いている」のではなく「担当が割れていて落ちている」と論じられる。

### 実務上の意味

SSHM が**現に稼働している**ことは、提案の出し口があるということでもある。本研究の成果は最終的に個人 I-D → SSHM への採択提案という経路を取りうる。論文の Future Work に書ける具体性がある。

ただし憲章が「maintain」に限定されているため、新機能の提案は憲章の範囲外と見なされる可能性がある。**その場合は SEAT の SSH 版として別 WG / BOF を狙う筋もある。**

### 最優先の次アクション

**`draft-ietf-sshm-hostkey-update-00` "Host key update mechanism for SSH" を読む。** ホスト鍵の信頼更新を扱う現行の WG 文書であり、本研究と問題意識が最も近い。ここで TOFU がどう扱われているかは、提案の差別化に直結する。

## 未解決・気になる点

- WG の設立時期（憲章ページに明示なし、`charter-ietf-sshm-01` が Approved とだけ）
- SSHM の ML で attestation / TPM が話題になったことはあるか
- 憲章の「maintain」の解釈はどこまで広いか。新しい信頼モデルの提案は受け入れられる余地があるか
- `draft-ietf-sshm-hostkey-update` の中身（未読）
