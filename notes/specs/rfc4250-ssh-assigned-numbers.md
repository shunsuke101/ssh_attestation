---
id: "rfc:4250"
title: "The Secure Shell (SSH) Protocol Assigned Numbers"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4250"
type: spec
tags: [ssh, core-spec, iana, message-numbers, private-use, name-at-domain, extension-points, rfc4250]
relevance: high
added: 2026-09-09
---

> 中核 5 本の全体像は [[ssh-core-rfcs]]（地図）を参照。本ノートは RFC 4250 単体の精読。

## 何を規定しているか

SSH の IANA レジストリの**初期状態**と、**将来の割り当て手続き**を定めるだけの RFC（2006-01）。著者は S. Lehtinen と C. Lonvick (Ed.)。

> This document does not define any new protocols. It is intended only to create the initial state of the IANA databases for the SSH protocol and also contains instructions for future assignments. — §1

**新しいプロトコルを一切定義しない。** 中身は「番号と名前をどう取るか」だけ。だが本研究にとっては、**プロトコル拡張の入口がどこに開いているかを定義する文書**であり、問い 1（どのレイヤに載せるか）と問い 2（後方互換性）に最も直接効く。

## 本研究に効く定義・要件

### メッセージ番号の割り当てと、将来の取得手続き（§4.1）

| 範囲 | 用途 | 新規取得の手続き（§4.1.3） |
|---|---|---|
| 1–19 | トランスポート層 generic（disconnect, ignore, debug 等） | **STANDARDS ACTION** |
| 20–29 | アルゴリズム交渉 | STANDARDS ACTION |
| **30–49** | **鍵交換方式ごとに固有**（方式が違えば同じ番号を再利用してよい） | **不要。その方式の定義文書が意味を決める** |
| 50–59 | ユーザ認証 generic | STANDARDS ACTION |
| **60–79** | **ユーザ認証方式ごとに固有**（方式が違えば再利用可） | **不要。その方式の定義文書が意味を決める** |
| 80–89 | コネクションプロトコル generic | STANDARDS ACTION |
| 90–127 | チャネル関連 | STANDARDS ACTION |
| 128–191 | クライアントプロトコル用に予約 | IETF CONSENSUS |
| **192–255** | **Local extensions** | **手続き不要。`The IANA will not control the message numbers in the range of 192 through 255. This range will be left for PRIVATE USE.`** |

**この表が本研究の設計自由度そのもの。** 新しいメッセージを足す方法が 3 通りあり、コストが全く違う（後述）。

### 名前の規約（§4.6.1）— `name@domainname`

IANA 登録名は printable US-ASCII、**`@` / `,` / 空白 / 制御文字 / DEL を含んではならない**、case-sensitive、**64 文字以内**。

そのうえで局所拡張の穴が開けてある:

> A provision is made here for locally extensible names. The IANA will not register, and will not control, names with the at-sign in them. — §4.6.1

`name@domainname` 形式なら誰でも定義してよい。`@` は 1 個だけ、後半は定義者が管理する FQDN、全体で 64 文字以内。OpenSSH の `hostkeys-00@openssh.com` 等がこの形。

### 名前空間の一覧（§4.7〜4.11）

拡張ポイントとして使える名前空間はこれだけある:

| 名前空間 | 初期値 | attestation を載せる余地 |
|---|---|---|
| Service Names (§4.7) | `ssh-userauth`, `ssh-connection` | 新サービス層を足せる |
| **Authentication Method Names (§4.8)** | `publickey`, `password`, `hostbased`, `none` | **新認証方式を足せる（60–79 の番号が自由に使える）** |
| Channel Types (§4.9.1) | `session`, `x11`, `forwarded-tcpip`, `direct-tcpip` | 専用チャネルを開ける |
| Global Request Names (§4.9.2) | `tcpip-forward` 等 | 接続全体に効く要求を足せる |
| Channel Request Names (§4.9.3) | `pty-req`, `exec` 等 | チャネル単位の要求を足せる |
| Subsystem Names (§4.9.5) | `sftp` | サブシステムとして実装できる |
| **Key Exchange Method Names (§4.10)** | `diffie-hellman-group1-sha1` 等 | **新 KEX 方式を足せる（30–49 の番号が自由に使える）** |
| Algorithm Names (§4.11) | 暗号 / MAC / 公開鍵 / 圧縮 | 公開鍵アルゴリズム名の新設 |

### PRIVATE USE 範囲の運用（§4.3.4）

チャネル接続失敗の reason code について、`0xFE000000`–`0xFEFFFFFF` は「局所定義のチャネル型と対で使う」、`0xFF` 始まりは「制限も推奨もない。相互運用は期待されない。要するに実験用」と書かれている。**局所拡張には局所エラーコードを対で用意する**という設計作法がここに示されている。

## 拡張点・自由度

この RFC はほぼ全体が「拡張点の定義」なので、逆に**規定していないこと**を挙げるほうが早い:

- 局所名前空間（`@domain` 付きの名前）の中身には一切関与しない
- メッセージ番号 192–255 の中身にも一切関与しない
- 30–49 と 60–79 の意味は、その KEX 方式／認証方式の定義文書に丸投げ

## 他仕様との関係

- 初期値の出典: RFC 4251 / 4252 / 4253 / 4254（この 4 本で定義済みの番号と名前を IANA 表に移しただけ）
- 更新: RFC 8268, 9142, 9519（→ [[ssh-core-rfcs]] と [[iana-ssh-registry-and-extension-points]]）
- RFC 4251 §6 / §7 と内容がほぼ重複する（名前の規約とメッセージ番号範囲）。**同じ規約が 2 か所に書かれている**ので、論文で引くときはどちらを引くか決めておく

## 引用すべき箇所

> This document does not define any new protocols. It is intended only to create the initial state of the IANA databases for the SSH protocol and also contains instructions for future assignments.
> — RFC 4250, §1

> The IANA will not control the message numbers in the range of 192 through 255. This range will be left for PRIVATE USE.
> — RFC 4250, §4.1.3

> A provision is made here for locally extensible names. The IANA will not register, and will not control, names with the at-sign in them.
> — RFC 4250, §4.6.1

## 自研究との関係

（※ここは解釈）

**問い 1（どのレイヤに載せるか）は、この RFC の表を見ると「コスト構造の異なる 4 択」に整理できる。**

| 載せ方 | 使えるメッセージ番号 | IANA 手続き | 評価 |
|---|---|---|---|
| **新しい KEX 方式として定義** | 30–49 を自由に | KEX 方式名の登録のみ（名前は `@domain` で回避可） | **ホスト認証と同時に走る＝ TOFU の所在に直接届く。番号も自由。最有力** |
| **新しいユーザ認証方式として定義** | 60–79 を自由に | 認証方式名の登録のみ | クライアント→サーバの attestation なら自然。ただしトランスポート層のサーバ認証は既に終わっている |
| 新しいトランスポート層 generic メッセージ | 1–19 を新規取得 | **STANDARDS ACTION** | 最も重い。RFC 化が前提 |
| 局所拡張として実装 | **192–255** | **不要** | **fork での実装・評価にはこれ。相互運用は放棄** |

**実装リポジトリ（openssh-portable の fork）での当面の方針が決まる。** プロトタイプ段階では 192–255 の PRIVATE USE 番号と `attestation@<自ドメイン>` 形式の名前を使えば、IANA 手続きも RFC 化も待たずに実装・評価ができる。標準化を狙う段になったら、KEX 方式または認証方式として定義し直す（そのとき 30–49 / 60–79 に移せば番号の取り合いが起きない）。**この 2 段構えは §4.1.3 と §4.6.1 が明示的に許している道筋**であり、後付けの言い訳ではない。

**問い 2（後方互換性）にも効く。** 局所拡張名は「知らない実装は単に無視する／`SSH_MSG_UNIMPLEMENTED` を返す」という既定の振る舞い（RFC 4253 §11.4）と組み合わさって、段階的導入の土台になる。ただし**鍵交換の段階で未知のメッセージを送ると接続が壊れる可能性**があるので、KEX 方式として定義する場合は「方式名の交渉で合意した相手にしか送らない」形になる——これは RFC 4253 §7.1 のアルゴリズム交渉がそのまま能力交渉として使えるということでもある。

## 未解決・気になる点

- RFC 9519 が登録ポリシーを Expert Review に緩和した（Message Numbers は Standards Action のまま）と [[ssh-core-rfcs]] にあるが、**本ノートでは一次情報を当たっていない**。KEX 方式名・認証方式名の登録が実際どこまで軽くなったかは要確認
- 30–49 の「方式ごとに再利用可」は、**同一接続で複数の KEX 方式が同時に走らない**前提。attestation を KEX に載せる場合、番号衝突が起きない保証はこの前提に依存する。RFC 4253 §7.1 を読む限り問題ないはずだが、rekey（§9）時の扱いは要確認
- 現在の IANA レジストリの実際の状態（登録済みの KEX 方式名・認証方式名の一覧）は未取得。名前の衝突回避のため、実装前に一度取る → [[iana-ssh-registry-and-extension-points]]
