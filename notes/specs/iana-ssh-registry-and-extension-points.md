---
id: "url:https://www.iana.org/assignments/ssh-parameters/ssh-parameters.xhtml"
title: "Secure Shell (SSH) Protocol Parameters (IANA registry)"
body: "IANA"
status: "Registry (live)"
year: unknown
url: "https://www.iana.org/assignments/ssh-parameters/ssh-parameters.xhtml"
type: spec
tags: [ssh, iana, message-numbers, extension-points, rfc4250, rfc8308, rfc9519, ext-info]
relevance: high
added: 2026-08-21
---

> **本研究にとって最重要のノート。** 「attestation を SSH のどこに挿せるか」という中心的な問い 1 は、最終的にこのレジストリの空き枠と登録ポリシーの問題に還元される。

## メッセージ番号レジストリ（1 バイト空間）

| 範囲 | 割り当て |
|---|---|
| 0 | Reserved |
| 1–6 | Transport layer generic |
| **7–8** | **Extension-related messages**（`SSH_MSG_EXT_INFO` 等、RFC 8308） |
| **9–19** | **Unassigned (Transport layer generic)** |
| 20–21 | Key exchange messages |
| **22–29** | **Unassigned (Algorithm negotiation)** |
| 30–49 | Reserved (key exchange method specific) |
| 50–53 | User authentication messages |
| **54–59** | **Unassigned (User authentication generic)** |
| 60–61 | Keyboard-interactive authentication |
| 62–79 | Reserved (User authentication method specific) |
| 80–82 | Global request messages |
| **83–89** | **Unassigned (Connection protocol generic)** |
| 90–100 | Channel-related messages |
| **101–127** | **Unassigned (Channel related messages)** |
| 128–191 | Reserved (for client protocols) |
| **192–255** | **Reserved for Private Use (local extensions)** |

レジストリは全部で 26 個のサブレジストリを持つ（メッセージ番号、切断理由コード、認証方式名、暗号アルゴリズム名、公開鍵アルゴリズム名、拡張名 など）。

## 登録ポリシー（RFC 9519, 2024 が変更）

**これが設計判断を大きく左右する。**

| 対象 | 従来 | RFC 9519 以降 |
|---|---|---|
| ほとんどのサブレジストリ（Authentication Method Names, Public Key Algorithm Names, **Extension Names**, KEX Method Names ほか十数個） | IETF Review | **Expert Review**（指名専門家が 3 週間で審査。IETF 全体の合意は不要） |
| **Message Numbers** | Standards Action | **Standards Action のまま**（1 バイト空間で希少なため） |
| Publickey Subsystem Status Codes | Standards Action | Standards Action のまま |

### この非対称性の含意

**新しいメッセージ番号を取るのは重い（Standards Action = RFC が要る）。一方、新しい "Extension Name" や "Public Key Algorithm Name" や "Authentication Method Name" を取るのは軽い（Expert Review）。**

したがって attestation を SSH に載せる設計は、**メッセージ番号を新設しない方向に強く誘導される**。具体的には:

| 手段 | 必要な手続き | 実現性 |
|---|---|---|
| 新規メッセージ番号 | Standards Action | 重い。ただし 9–19 / 54–59 / 83–89 に空きはある |
| **RFC 8308 の拡張名を新設** | **Expert Review** | **軽い。第一候補** |
| 新規 public key algorithm name（証明書型として） | Expert Review | 軽い |
| 新規 authentication method name | Expert Review | 軽い |
| Private Use 範囲（192–255）で実験 | 手続き不要 | プロトタイプ用。**OpenSSH 自身が SSH2_MSG_PING=192 / PONG=193 で実際にこれをやっている** |

## RFC 8308 の拡張交渉機構（＝正規の拡張点）

RFC 8308 "Extension Negotiation in the Secure Shell (SSH) Protocol" (D. Bider, 2018-03) が定める機構:

1. `SSH_MSG_KEXINIT` の `kex_algorithms` フィールドに指示子名を入れて対応を表明する（サーバは `ext-info-s`、クライアントは `ext-info-c`）
2. 鍵交換後に **`SSH_MSG_EXT_INFO`** メッセージで拡張名と値の組を交換する
3. サーバが送るタイミングは 2 箇所ある（**鍵交換の直後** と **認証成功の直前**）

RFC 4251 / 4252 / 4253 / 4254 のすべてを更新している。RFC 9519 に更新された。

**タイミングの 2 択が本研究に直接効く。** 「鍵交換の直後」に Evidence を送れるなら、**ユーザ認証が始まる前にホストの状態を検証できる**。これは PAM 方式（[[hardwareprotectedssh-bidirectional-tpm-attestation]]）が構造的に到達できない位置。

## 引用すべき箇所

> a mechanism for Secure Shell (SSH) clients and servers to exchange information about supported protocol extensions confidentially after SSH key exchange
> — RFC 8308, Abstract

> The "Message Numbers" and "Publickey Subsystem Status Codes" registries retain Standards Action requirements due to their limited one-byte value space.
> — RFC 9519 の内容（※datatracker/rfc-editor の要約に基づく。**原文の正確な文言は要確認**）

## 自研究との関係

（※ここは解釈）

**設計の骨格がこのノートで決まる。** 提案は次の形が最も現実的:

1. `SSH_MSG_EXT_INFO`（鍵交換直後のタイミング）で attestation 対応を表明する拡張名を定義する
2. Evidence 本体は、拡張値として運ぶか、新設の host key algorithm（＝ attestation 付きホスト鍵型）として運ぶ
3. どちらも **Expert Review** で登録可能。新メッセージ番号を避けられる
4. プロトタイプ実装は 192–255 の Private Use 範囲で先に作れる（OpenSSH の PING/PONG が前例）

この道筋は [[draft-fossati-seat-expat]] が TLS で選んだ「コアを変えず既存の拡張点に載せる」方針と一致する。**TLS 側がハンドシェイク拡張路線を捨てた理由が「重すぎる」ことなら、SSH でも同じ判断になる。**

## 未解決・気になる点

- RFC 8308 の「認証成功の直前」タイミングは、ホスト attestation には遅すぎるか。**鍵交換直後のタイミングで Evidence を送れるかを原文で確認する**（`SSH_MSG_EXT_INFO` の送信可能タイミングの規定）
- 拡張値のサイズ上限。TPM Quote + イベントログは数十 KB になりうる。`SSH_MSG_EXT_INFO` にそれを載せられるか
- Extension Names サブレジストリの現在の登録状況（何が既にあるか）
- RFC 9519 の原文を未取得。上表は要約に基づく
