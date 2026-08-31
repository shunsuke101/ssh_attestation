---
id: "rfc:4251"
title: "The Secure Shell (SSH) Protocol Architecture"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4251"
type: spec
tags: [ssh, core-spec, transport-layer, userauth, connection-protocol, rfc4251, rfc4252, rfc4253, rfc4254, rfc4250]
relevance: high
added: 2026-08-21
---

> **このノートは SSH 中核仕様群の地図。** 個別 RFC の詳細ではなく「何がどこに書いてあるか」「何がそれを更新したか」を引くための索引として使う。

## 中核 5 本（すべて 2006-01、すべて Proposed Standard）

著者はいずれも T. Ylonen と C. Lonvick (Ed.)（RFC 4250 のみ S. Lehtinen と C. Lonvick (Ed.)）。

| RFC | タイトル | 役割 | Updated by |
|---|---|---|---|
| **4250** | The Secure Shell (SSH) Protocol Assigned Numbers | IANA レジストリの初期状態とメッセージ番号の割り当て | 8268, 9142, 9519 |
| **4251** | The Secure Shell (SSH) Protocol Architecture | 3 層アーキテクチャ、用語、データ表現、アルゴリズム命名規則、Security Considerations | 8308, 9141 |
| **4252** | The Secure Shell (SSH) Authentication Protocol | ユーザ認証の枠組みと publickey / password / hostbased の 3 方式 | 8308, 8332 |
| **4253** | The Secure Shell (SSH) Transport Layer Protocol | 暗号化・サーバ認証・完全性、アルゴリズム交渉、DH 鍵交換 | 6668, 8268, 8308, 8332, 8709, 8758, 9142 |
| **4254** | The Secure Shell (SSH) Connection Protocol | チャネル多重化、対話ログイン、ポート転送、X11 転送 | 8308 |

**いずれも Obsoleted by は無い。** 20 年前の仕様が現役のまま、更新 RFC を積み重ねる形で維持されている。

## 3 層アーキテクチャ（RFC 4251）

| 層 | 規定 | 何を保証するか | 本研究との関係 |
|---|---|---|---|
| **Transport Layer Protocol** | RFC 4253 | **サーバ認証**、暗号化、完全性 | **ここでホスト鍵の所持証明が行われる。本研究が手を入れたい層** |
| **User Authentication Protocol** | RFC 4252 | クライアント（ユーザ）の認証 | トランスポート層の上で走る。既存の TPM 実装（PAM 系）はここに閉じている |
| **Connection Protocol** | RFC 4254 | チャネル多重化 | 認証完了後。attestation を置くには遅すぎる可能性 |

**重要な含意**: サーバ認証は**トランスポート層で完結してしまう**。RFC 4253 の時点でクライアントはホスト鍵を受け入れるか否かを決めており、その判断材料は「鍵が既知か」だけ。ここが TOFU の所在。ユーザ認証層で何をしても、**その時点では既にホストを信頼済み**である。

## 主な更新 RFC（確認済み）

| RFC | タイトル | 何を変えたか |
|---|---|---|
| **8308** (2018-03, D. Bider) | Extension Negotiation in the Secure Shell (SSH) Protocol | **`SSH_MSG_EXT_INFO` による拡張交渉機構を導入。** 4251/4252/4253/4254 のすべてを更新。→ [[iana-ssh-registry-and-extension-points]] |
| **9142** (2022, M. Baushke) | Key Exchange (KEX) Method Updates and Recommendations for Secure Shell (SSH) | KEX の推奨更新。SHA-1 系の段階的廃止、`diffie-hellman-group14-sha256` を必須に。4250/4253/4432/4462 を更新 |
| **9519** (2024, P. Yee) | Update to the IANA SSH Protocol Parameters Registry Requirements | **登録ポリシーを IETF Review から Expert Review に緩和**（Message Numbers は Standards Action のまま）。4250/4716/4819/8308 を更新。→ [[iana-ssh-registry-and-extension-points]] |
| **9987** (2026-05, D. Miller) | Secure Shell (SSH) Agent Protocol | **ssh-agent プロトコルがついに RFC 化された。** SSHM WG 産 |
| **9941** (2026-04) | SSH Key Exchange Method Using Hybrid Streamlined NTRU Prime sntrup761 and X25519 with SHA-512 | PQC 系 KEX（Informational） |

### 未取得の更新 RFC（次回トリアージ）

RFC 4253 を更新する **6668, 8268, 8332, 8709, 8758**、RFC 4251 を更新する **9141** は、番号のみ確認済みで一次情報を当たっていない。書誌情報を推測で埋めないため `seen.jsonl` には未登録。次の `/collect` で拾う。

## 自研究との関係

（※ここは解釈）

**前提** — Background 節で SSH の 3 層構造と「サーバ認証がトランスポート層で完結する」ことを説明するのに必須。

設計上、この地図から読み取れる制約は 3 つ:

1. **中核 5 本は Obsolete されていない。** つまり本研究の提案は「4253 を置き換える」ではなく「4253 を **update** する新 RFC」の形を取るのが自然。前例（8308, 9142）がある
2. **サーバ認証はトランスポート層で閉じる。** ユーザ認証層に attestation を置く設計（＝ [[hardwareprotectedssh-bidirectional-tpm-attestation]] の PAM 方式）は、**構造上 TOFU を解けない**。この論証は論文で使える
3. **RFC 8308 が既に「後から拡張を足す」正規の穴を開けている。** ゼロから機構を作る必要はない

## 未解決・気になる点

- RFC 4251 の Security Considerations は TOFU について何と書いているか（原文精読が要る。**論文で「仕様自身が TOFU の限界を認めている」と引けるかどうかが懸かる**）
- RFC 9141 が RFC 4251 の何を更新したか
- ホスト鍵の検証方法について RFC 4251/4253 はどこまで規定し、どこから実装依存か
