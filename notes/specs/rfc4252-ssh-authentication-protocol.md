---
id: "rfc:4252"
title: "The Secure Shell (SSH) Authentication Protocol"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4252"
type: spec
tags: [ssh, core-spec, userauth, publickey, hostbased, session-identifier, partial-success, method-namespace, rfc4252]
relevance: high
added: 2026-09-09
---

> 中核 5 本の全体像は [[ssh-core-rfcs]]（地図）を参照。本ノートは RFC 4252 単体の精読。
> **attestation の方向をクライアント→サーバに定めた以上、この層が第 1 候補地の一つになる。**

## 何を規定しているか

SSH のユーザ認証層（2006-01、T. Ylonen / C. Lonvick (Ed.)）。トランスポート層（[[rfc4253-ssh-transport-layer]]）の上で走り、**クライアントをサーバに認証する**。サービス名は `ssh-userauth`。

認証方式の**枠組み**と、`publickey`（REQUIRED）/ `password`（OPTIONAL）/ `hostbased`（OPTIONAL）/ `none`（NOT RECOMMENDED）の 4 方式を定義する。

## 本研究に効く定義・要件

### §4 サーバ主導の枠組み

> The server drives the authentication by telling the client which authentication methods can be used to continue the exchange at any given time. The client has the freedom to try the methods listed by the server in any order. — §4

サーバが「今どの方式で続行できるか」を提示し、クライアントが順序を選ぶ。**サーバが認証プロセスを完全に制御できる**設計。

推奨値: 認証タイムアウト 10 分、失敗試行の上限 20 回。

### §5 認証要求の共通形式 — 拡張の型

```
byte      SSH_MSG_USERAUTH_REQUEST
string    user name (UTF-8)
string    service name (US-ASCII)
string    method name (US-ASCII)
....      method specific fields
```

**`method name` 以降は方式ごとに自由**。新しい認証方式を定義するとは、この `method specific fields` の中身を決めることに等しい。方式名は [[rfc4251-ssh-architecture]] / [[rfc4250-ssh-assigned-numbers]] の命名規則に従う＝ **`attestation@example.com` のような局所名なら登録なしで定義できる**。

> Additional 'method name' values may be defined as specified in [SSH-ARCH] and [SSH-NUMBERS]. — §5

さらに:

> While there is usually little point for clients to send requests that the server does not list as acceptable, sending such requests is not an error, and the server SHOULD simply reject requests that it does not recognize. — §5

**知らない方式を投げられてもサーバは単に拒否するだけ**。接続は壊れない。段階的導入の根拠。

### §5.1 partial success — 多段認証の既製機構

```
byte         SSH_MSG_USERAUTH_FAILURE
name-list    authentications that can continue
boolean      partial success
```

`partial success` が TRUE なら「この方式自体は成功したが、まだ認証は完了していない」。`SSH_MSG_USERAUTH_SUCCESS` は認証が**すべて**完了したときに一度だけ送られる。

**これは「公開鍵認証 + attestation」を連結する既製の仕組み**。attestation を独立した認証方式として定義すれば、`publickey` の後に `attestation@...` を要求する多段構成が、仕様に手を入れずに書ける。

### §6 メッセージ番号 — 60–79 の自由

- 50–53: `SSH_MSG_USERAUTH_REQUEST` / `FAILURE` / `SUCCESS` / `BANNER`
- **60–79: 方式固有。「異なる認証方式は同じ番号を再利用する」**
- 80 以上を認証完了前に受け取ったらサーバは切断しなければならない (MUST)

> In addition to the above, there is a range of message numbers (60 to 79) reserved for method-specific messages. These messages are only sent by the server (client sends only SSH_MSG_USERAUTH_REQUEST messages). Different authentication methods reuse the same message numbers. — §6

**注意すべき制約**: 60–79 は**サーバのみが送る**とされ、クライアントは `SSH_MSG_USERAUTH_REQUEST` しか送らない。チャレンジ・レスポンス型を作るなら、サーバの challenge は 60–79、クライアントの response は `SSH_MSG_USERAUTH_REQUEST` に載せる形になる（[[rfc4256-keyboard-interactive]] は実際そうしていない——後述）。

### §7 publickey — session identifier への束縛

事前確認（`boolean FALSE` で鍵だけ提示 → `SSH_MSG_USERAUTH_PK_OK`）と、本番の署名付き要求（`boolean TRUE`）の 2 段構え。署名の対象データが本研究に効く:

```
string    session identifier      ← ★
byte      SSH_MSG_USERAUTH_REQUEST
string    user name
string    service name
string    "publickey"
boolean   TRUE
string    public key algorithm name
string    public key to be used for authentication
```

**先頭に session identifier（= 最初の KEX の exchange hash H）が入る。** これがユーザ認証を SSH セッションに束縛している仕組み。詳細は [[rfc4253-ssh-transport-layer]] §7.2。

もう一点:

> Any public key algorithm may be offered for use in authentication. In particular, the list is not constrained by what was negotiated during key exchange. If the server does not support some algorithm, it MUST simply reject the request. — §7

**認証で使う公開鍵アルゴリズムは KEX の交渉結果に縛られない。** 鍵 blob には証明書を含めてよい（[[rfc4253-ssh-transport-layer]] §6.6）。

### §9 hostbased — もう一つの参照実装

`hostbased` はクライアント**ホスト**の鍵で署名する方式。ユーザではなくマシンを認証するという点で、本研究の方向（クライアント端末の attestation）に構造が近い。未精読。

## 拡張点・自由度

- **新しい認証方式を定義できる**（§5。方式名は局所名前空間で可、60–79 の番号は方式固有）
- 方式固有フィールドの中身は完全に自由
- 多段認証は `partial success` で既に表現できる（§5.1）
- 認証で使う公開鍵アルゴリズムは KEX の交渉と独立（§7）
- 知らない方式は拒否されるだけ（§5）

## 他仕様との関係

- 下位層: [[rfc4253-ssh-transport-layer]]（session identifier の出所、公開鍵アルゴリズムの枠組み）
- 土台: [[rfc4251-ssh-architecture]]（命名規則）／ [[rfc4250-ssh-assigned-numbers]]（方式名レジストリ）
- 追加方式: [[rfc4256-keyboard-interactive]]（`keyboard-interactive`）、GSS-API（RFC 4462）
- 更新: RFC 8308（拡張交渉）、8332（rsa-sha2）→ [[ssh-core-rfcs]]
- 既存の TPM 実装との関係: [[hardwareprotectedssh-bidirectional-tpm-attestation]] はこの層（PAM 経由）に閉じている

## 引用すべき箇所

> The server drives the authentication by telling the client which authentication methods can be used to continue the exchange at any given time.
> — RFC 4252, §4

> The value of 'signature' is a signature by the corresponding private key over the following data, in the following order: string session identifier, byte SSH_MSG_USERAUTH_REQUEST, ...
> — RFC 4252, §7

> Additional 'method name' values may be defined as specified in [SSH-ARCH] and [SSH-NUMBERS].
> — RFC 4252, §5

> Any public key algorithm may be offered for use in authentication. In particular, the list is not constrained by what was negotiated during key exchange.
> — RFC 4252, §7

## 自研究との関係

（※ここは解釈）

**この層に載せる設計の利点は 3 つある。**

1. **束縛が既にある。** §7 の署名対象の先頭が session identifier なので、attestation Evidence を同じ形で署名すれば、それが「この接続のために作られた」ことを示せる。[[rfc4253-ssh-transport-layer]] に書いた通り、session identifier にはサーバの cookie 由来の予測不能性が入っている
2. **多段構成がタダで書ける。** `partial success`（§5.1）により「公開鍵認証を通ったうえで、さらに attestation を要求する」がプロトコル変更なしに表現できる。**問い 2（段階的導入）に対する最も安価な答え**
3. **サーバが完全に主導権を持つ**（§4）。Verifier をサーバに置く本研究の構成（→ `docs/glossary.md`）と噛み合う。サーバのポリシーで「この鍵のユーザには attestation を要求する」と決められる

**一方、この層の構造的な限界も明確。** [[ssh-core-rfcs]] に既に書かれている通り、ユーザ認証が始まる時点で**トランスポート層のサーバ認証は完了済み**である。つまり:

- **サーバ→クライアント方向の attestation（接続先ホストの状態検証）はこの層では手遅れ。** TOFU は既に発生している
- **クライアント→サーバ方向（本研究が定めた向き）なら問題ない。** クライアントの状態をサーバが検証するのだから、順序として自然

**したがって「方向をクライアント→サーバに定めた」という判断は、そのまま「この層に載せる選択肢が開いた」ことを意味する。** 逆に将来 attestation を双方向に広げるなら、サーバ側は KEX 層（[[rfc4253-ssh-transport-layer]]）に置かざるを得ず、層をまたぐ設計になる。この非対称性は論文で明示的に論じる価値がある。

**§6 の制約が設計を縛る。** 60–79 はサーバのみが送る、クライアントは `SSH_MSG_USERAUTH_REQUEST` しか送らない、という規定がある。RATS の Challenge/Response をこの層に載せるなら:

```
S → C: 60番台のメッセージ（Handle = nonce を含む）
C → S: SSH_MSG_USERAUTH_REQUEST（method specific fields に Evidence）
```

という形になる。**ただし [[rfc4256-keyboard-interactive]] は 61 番をクライアントからのレスポンスに使っており、§6 の記述と食い違う。** 先行例があるので厳密な制約ではないのかもしれない——要確認（→ 4256 ノートに詳述）。

## 未解決・気になる点

- **§9 hostbased が未読。** マシンを認証するという構造が本研究に近いので、脅威モデルと署名対象を確認すべき
- §11 Security Considerations が未読
- §6 の「60–79 はサーバのみが送る」と RFC 4256 の実際の使い方の食い違い（→ [[rfc4256-keyboard-interactive]]）
- RFC 8308 の `SSH_MSG_EXT_INFO` がこの層のどこに割り込むか。認証方式の能力交渉に使えるなら、方式名リストより上品な能力交渉ができる可能性 → [[iana-ssh-registry-and-extension-points]]
- 認証方式として定義した場合、**Evidence のサイズが `SSH_MSG_USERAUTH_REQUEST` 1 パケットに収まるか**（32768 バイト制約、→ [[rfc4253-ssh-transport-layer]] §6.1）。イベントログを含めると厳しい
