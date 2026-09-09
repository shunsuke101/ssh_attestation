---
id: "rfc:4256"
title: "Generic Message Exchange Authentication for the Secure Shell Protocol (SSH)"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4256"
type: spec
tags: [ssh, userauth, keyboard-interactive, challenge-response, pam, multi-round, one-time-password, rfc4256]
relevance: high
added: 2026-09-09
---

> 中核 5 本の地図は [[ssh-core-rfcs]]。本ノートは RFC 4256（`keyboard-interactive`）単体の精読。
> **SSH に既に存在する唯一の汎用チャレンジ・レスポンス機構。** RATS の Challenge/Response モデルとの対応を見るために読んだ。

## 何を規定しているか

ユーザ認証方式 **`keyboard-interactive`** を定義する（2006-01）。著者は F. Cusack（savecore.net）と M. Forssen（AppGate Network Security AB）。**中核 5 本には含まれないが、ユーザ認証層の実質的な第 5 の方式**として広く実装されている。

狙いは「認証方式とその背後の認証機構を切り離すこと」:

> Currently defined authentication methods for SSH are tightly coupled with the underlying authentication mechanism. This makes it difficult to add new mechanisms for authentication as all clients must be updated to support the new mechanism. With the generic method defined here, clients will not require code changes to support new authentication mechanisms, and if a separate authentication layer is used, such as [PAM], then the server may not need any code changes either. — §2

サーバが**プロンプトの列**を送り、クライアントがユーザに入力させて**回答の列**を返す。それだけの汎用機構。実体は PAM への橋渡しとして使われることが多い。

## 本研究に効く定義・要件

### §3 プロトコル交換 — 多ラウンドのチャレンジ・レスポンス

```
C → S: SSH_MSG_USERAUTH_REQUEST ("keyboard-interactive", language tag, submethods)
S → C: SSH_MSG_USERAUTH_INFO_REQUEST   (60)
C → S: SSH_MSG_USERAUTH_INFO_RESPONSE  (61)
S → C: SUCCESS / FAILURE / さらに INFO_REQUEST
```

**サーバは必要なだけ要求を繰り返してよい**が、未応答の `INFO_REQUEST` を 2 つ以上同時に持ってはならない (MUST NOT)。クライアントは複数回のやりとりに対応できなければならない (MUST)。

### `SSH_MSG_USERAUTH_INFO_REQUEST`（60）

```
byte      SSH_MSG_USERAUTH_INFO_REQUEST
string    name (UTF-8)
string    instruction (UTF-8)
string    language tag        ← 非推奨。空文字列にすべき
int       num-prompts
string    prompt[1] (UTF-8)
boolean   echo[1]
...
```

### `SSH_MSG_USERAUTH_INFO_RESPONSE`（61）

```
byte      SSH_MSG_USERAUTH_INFO_RESPONSE
int       num-responses
string    response[1] (UTF-8)
...
```

`num-responses` が `num-prompts` と一致しなければサーバは失敗を返さなければならない (MUST)。**`num-prompts` が 0 の場合**、プロンプトなしのメッセージになり、クライアントは `num-responses` = 0 の応答を返して交換を完了させなければならない (MUST)。

### §2 が挙げる用途

> Challenge-response and One Time Password mechanisms are also easily supported with this authentication method. — §2

ただし限界も明記されている:

> However, this authentication method is limited to authentication mechanisms that do not require any special code, such as hardware drivers or password mangling, on the client. — §2

**「クライアント側に特別なコード（ハードウェアドライバ等）を要する機構には使えない」**——TPM を叩く必要がある attestation は、この但し書きに正面から抵触する（後述）。

### §6 Security Considerations

- この方式はトランスポート層の機密性に依存する。それなしでは認証データが傍受される
- **やりとりの回数が可変なので、回数を数えるだけで観測者が情報を得うる**（例: パスワード有効期限の推測）

### RFC 4252 §6 との食い違い（重要）

[[rfc4252-ssh-authentication-protocol]] §6 はこう書いている:

> In addition to the above, there is a range of message numbers (60 to 79) reserved for method-specific messages. **These messages are only sent by the server (client sends only SSH_MSG_USERAUTH_REQUEST messages).**

しかし RFC 4256 は **61 番（`SSH_MSG_USERAUTH_INFO_RESPONSE`）をクライアントから送らせている**。両者は同じ 2006-01 に発行された Standards Track RFC であり、明白に食い違う。

**実務的には RFC 4256 の側が実装されている**（OpenSSH を含め `keyboard-interactive` は広く動いている）。したがって RFC 4252 §6 の括弧書きは**厳密な規範ではなく、当時の方式群の記述**と読むべきだと思われる。**本研究が新しい認証方式でクライアント→サーバのメッセージを 60–79 に定義することは、先例がある。**

## 拡張点・自由度

- **`submethods` フィールド**: クライアントが使いたいサブメソッドをカンマ区切りで示唆できる。「実際のサブメソッド名はユーザとサーバが合意すべきもの」とされ、**サーバの解釈は実装依存**。名前空間が完全に開いている
- プロンプトの中身も回数も完全に自由
- `num-prompts` = 0 が許されている＝**ユーザ入力を伴わない往復**が仕様上可能

## 他仕様との関係

- 土台: [[rfc4252-ssh-authentication-protocol]]（認証枠組み）、[[rfc4251-ssh-architecture]]（用語・記法）、[[rfc4253-ssh-transport-layer]]（機密性）
- 参照: PAM（Informative）
- 番号: `keyboard-interactive` は [[rfc4250-ssh-assigned-numbers]] §4.8 の初期割り当てには**含まれない**（後から追加された方式）

## 引用すべき箇所

> Currently defined authentication methods for SSH are tightly coupled with the underlying authentication mechanism. This makes it difficult to add new mechanisms for authentication as all clients must be updated to support the new mechanism.
> — RFC 4256, §2

> Challenge-response and One Time Password mechanisms are also easily supported with this authentication method.
> — RFC 4256, §2

> However, this authentication method is limited to authentication mechanisms that do not require any special code, such as hardware drivers or password mangling, on the client.
> — RFC 4256, §2

> The number of client-server exchanges required to complete an authentication using this method may be variable. It is possible that an observer may gain valuable information simply by counting that number.
> — RFC 4256, §6

## 自研究との関係

（※ここは解釈）

**結論から言うと、`keyboard-interactive` に attestation を載せるのは筋が悪い。** ただし「なぜ筋が悪いか」を示すこと自体が論文の材料になる。

**載せられそうに見える理由**（先行実装が実際にこの道を通る）:

- SSH で唯一の**汎用チャレンジ・レスポンス**機構。RATS の Challenge/Response モデルと形が一致する
- サーバが nonce をプロンプトとして送り、クライアントが Evidence を回答として返す、という写像が自然に書ける
- `num-prompts` = 0 が許されているので、ユーザ入力なしの機械的な往復もできる
- **サーバ側もクライアント側もコード変更なしで済む**のが RFC 4256 の売り（PAM 経由）。既存の TPM 系実装（[[hardwareprotectedssh-bidirectional-tpm-attestation]]）がこの層を選ぶのは理にかなっている

**それでも筋が悪い理由**:

1. **§2 の但し書きに正面から抵触する。** 「クライアント側にハードウェアドライバのような特別なコードを要する機構には使えない」。TPM Quote の生成はまさにそれ。**RFC 4256 の設計意図の外**で使うことになる
2. **束縛が弱い。** 応答は単なる UTF-8 文字列であり、[[rfc4252-ssh-authentication-protocol]] §7 の publickey のような **session identifier への署名という構造を持たない**。Evidence を SSH セッションに暗号的に束縛する仕組みが方式自体には無く、プロンプト／応答の中に自前で詰め込むしかない
3. **応答が UTF-8 文字列**なので、バイナリの Evidence（TPM Quote、イベントログ）は Base64 等でエンコードする必要がある。サイズも膨らむ
4. **ユーザ認証層なので、サーバ→クライアント方向には使えない**（TOFU は既に済んでいる）。将来の双方向化に対して行き止まり
5. §6 が指摘する「往復回数から情報が漏れる」問題は、attestation の可否がやりとり回数に現れる設計だと現実の懸念になる

**したがって本研究の位置づけ**: `keyboard-interactive` は「SSH で attestation をやろうとすると最初に思いつく道」であり、実際に既存実装が通っている道でもある。**その道の限界（束縛の欠如、仕様の設計意図との齟齬）を明示したうえで、より適切な層を提案する**という構成にできる。Related Work で既存の PAM 方式を批判的に位置づける際の根拠が §2 の但し書きと §7（publickey の署名対象）の対比で作れる。

**副産物として有用な発見**: RFC 4252 §6 との食い違いにより、**60–79 のクライアント→サーバ送信には先例がある**ことが分かった。新方式を設計するときの制約が 1 つ減る。

## 未解決・気になる点

- **OpenSSH の `keyboard-interactive` 実装が実際にどこまで自由か**（応答文字列の長さ制限、往復回数の上限）。fork での実装検討時に `auth2-chall.c` を読むこと
- RFC 4256 は更新 RFC を持つか未確認（datatracker で要確認）
- §3.1 の `submethods` を attestation の能力交渉に流用できるか。名前空間が開いているので形式上は可能だが、上記の理由でこの層自体を採らないなら意味がない
- [[rfc4252-ssh-authentication-protocol]] §6 との食い違いについて、IETF 側に errata や後続の整理があるか未確認
