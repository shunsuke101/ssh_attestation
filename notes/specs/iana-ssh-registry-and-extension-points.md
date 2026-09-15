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

> 原文を精読した個別ノートは [[rfc8308-ssh-extension-negotiation]]（2026-09-15）。以下は概要。

RFC 8308 "Extension Negotiation in the Secure Shell (SSH) Protocol" (D. Bider, 2018-03) が定める機構:

1. `SSH_MSG_KEXINIT` の `kex_algorithms` フィールドに指示子名を入れて対応を表明する（サーバは `ext-info-s`、クライアントは `ext-info-c`）
2. 鍵交換後に **`SSH_MSG_EXT_INFO`** メッセージで拡張名と値の組を交換する
3. サーバが送るタイミングは 2 箇所ある（**鍵交換の直後** と **認証成功の直前**）

RFC 4251 / 4252 / 4253 / 4254 のすべてを更新している。RFC 9519 に更新された。

**タイミングの規定が本研究に効く。** クライアントは「鍵交換の直後」に EXT_INFO を送れるので、**ユーザ認証が始まる前にクライアントの能力（attestation 対応）を表明できる**。ただしこの位置には server challenge の往復が無いので、Evidence 本体の運搬には向かない（→ [[rfc8308-ssh-extension-negotiation]]）。

## 引用すべき箇所

> a mechanism for Secure Shell (SSH) clients and servers to exchange information about supported protocol extensions confidentially after SSH key exchange
> — RFC 8308, Abstract

> The only IANA SSH protocol parameter registries not affected are "Message Numbers" and "Publickey Subsystem Status Codes", as these remain Standards Action due to their limited resources as one-byte registry values.
> — RFC 9519, §2（2026-09-15 に原文で確認し、要約に基づく旧引用を差し替え）

## 自研究との関係

（※ここは解釈）

**設計の骨格がこのノートで決まる。** 研究テーマ（attestation をクライアント認証に拡張し、server の challenge と client の response で行う）に照らすと、提案は次の形が最も現実的:

1. **server challenge / client response の往復は、新しい Authentication Method Name（ユーザ認証方式）として定義する。** 方式固有メッセージ番号 60–79 は方式ごとに再利用できるので、**新しいメッセージ番号の取得が要らない**（→ [[rfc4252-ssh-authentication-protocol]]）
2. attestation 対応の表明は、`SSH_MSG_EXT_INFO`（鍵交換直後）の拡張名、または認証方式名の提示（`SSH_MSG_USERAUTH_FAILURE` の name-list）で行う
3. 認証方式名も拡張名も **Expert Review** で登録可能。Standards Action の Message Numbers を避けられる
4. プロトタイプ実装は 192–255 の Private Use 範囲と `@domain` 形式の名前で先に作れる（OpenSSH の PING/PONG が前例）

（旧版では「Evidence 本体を拡張値か attestation 付きホスト鍵型として運ぶ」としていたが、それはホスト attestation を前提にした案で、現在の研究テーマ（クライアント認証）には合わないため改めた。2026-09-15）

この道筋は [[draft-fossati-seat-expat]] が TLS で選んだ「コアを変えず既存の拡張点に載せる」方針と一致する。**TLS 側がハンドシェイク拡張路線を捨てた理由が「重すぎる」ことなら、SSH でも同じ判断になる。**

## 未解決・気になる点

- ~~鍵交換直後のタイミングで Evidence を送れるか~~ → **2026-09-15 解決。送れる。** クライアントは「最初の `SSH_MSG_NEWKEYS` の直後の 1 パケット」でのみ送れる (MUST)。サーバは同じ位置と `SSH_MSG_USERAUTH_SUCCESS` の直前の 2 回。いずれもユーザ認証より前（サーバの第 2 の機会を除く）。ただし**最初の鍵交換の後にしか送れず、rekey のたびに送り直す仕組みはない**。詳細は [[rfc8308-ssh-extension-negotiation]]
- ~~拡張値のサイズ上限~~ → **2026-09-15 解決。** 拡張値に固有の上限はなく、RFC 4253 のパケット長だけが上限（全実装が保証するのは非圧縮ペイロード 32768 バイト）。TPM Quote は収まるが、イベントログは入らない可能性が高い。→ [[rfc8308-ssh-extension-negotiation]] §2.5
- Extension Names サブレジストリの現在の登録状況（何が既にあるか）
- ~~RFC 9519 の原文を未取得。上表は要約に基づく~~ → **2026-09-15 原文で確認。** 影響を受けないのは "Message Numbers" と "Publickey Subsystem Status Codes" だけで、他のサブレジストリ（Extension Names、Key Exchange Method Names 等）は Expert Review。登録は `ssh-reg-review@ietf.org` での 3 週間のレビュー期間の後に行われる
