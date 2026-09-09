---
id: "rfc:4254"
title: "The Secure Shell (SSH) Connection Protocol"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4254"
type: spec
tags: [ssh, core-spec, connection-protocol, channels, global-request, channel-request, subsystem, port-forwarding, rfc4254]
relevance: medium
added: 2026-09-09
---

> 中核 5 本の全体像は [[ssh-core-rfcs]]（地図）を参照。本ノートは RFC 4254 単体の精読。
> **本研究にとっては「載せられるが、載せるべきでない層」。** その理由を確定させるために読んだ。

## 何を規定しているか

SSH のコネクションプロトコル（2006-01、T. Ylonen / C. Lonvick (Ed.)）。サービス名は `ssh-connection`。**認証済みのトンネルを複数の論理チャネルに多重化する**層。対話セッション、リモートコマンド実行、TCP/IP ポート転送、X11 転送を規定する。

**この層が動くのはユーザ認証が完了した後**。したがって attestation をここに置くと、「信頼できるか分からない相手を既に受け入れた後で状態を確認する」ことになる。

## 本研究に効く定義・要件

### §4 Global Requests — 接続全体に効く要求

```
byte      SSH_MSG_GLOBAL_REQUEST
string    request name (US-ASCII)
boolean   want reply
....      request-specific data
```

> The value of 'request name' follows the DNS extensibility naming convention outlined in [SSH-ARCH]. — §4

**クライアントもサーバもいつでも送ってよく、受信側は適切に応答しなければならない。** 認識できない要求には単に `SSH_MSG_REQUEST_FAILURE` を返す。応答は要求と同じ順序で返さなければならない (REQUIRED)。

**双方向に非同期で送れる唯一の汎用メッセージ**という点が特徴。

### §5.1 チャネルオープン

```
byte      SSH_MSG_CHANNEL_OPEN
string    channel type (US-ASCII)
uint32    sender channel
uint32    initial window size
uint32    maximum packet size
....      channel type specific data
```

`channel type` も局所拡張名（`name@domain`）が使える。**フロー制御付きの独立したデータストリーム**を開ける。

### §5.4 チャネル固有要求

```
byte      SSH_MSG_CHANNEL_REQUEST
uint32    recipient channel
string    request type (US-ASCII)
boolean   want reply
....      type-specific data
```

> 'request type' names follow the DNS extensibility naming convention outlined in [SSH-ARCH] and [SSH-NUMBERS]. — §5.4

**このメッセージはウィンドウ空間を消費せず、空きがなくても送れる。** 認識できない要求には `SSH_MSG_CHANNEL_FAILURE` が返るだけ。

### §6.5 サブシステム

`subsystem` チャネル要求により、名前付きのサブシステムを起動できる（`sftp` がその例）。**独立したプロトコルを SSH の上に載せる正規の方法**。

## 拡張点・自由度

この層は拡張点だらけで、しかもどれも登録不要（局所名前空間で足りる）:

| 拡張点 | 形式 | 未対応時の挙動 |
|---|---|---|
| Global request | `name@domain` | `SSH_MSG_REQUEST_FAILURE` |
| Channel type | `name@domain` | `SSH_MSG_CHANNEL_OPEN_FAILURE` |
| Channel request | `name@domain` | `SSH_MSG_CHANNEL_FAILURE` |
| Subsystem | 名前 | 起動失敗 |

**いずれも「知らなければ失敗を返すだけで接続は壊れない」。** 実装コストが最も低い拡張点がこの層に集中している。

## 他仕様との関係

- 下位層: [[rfc4252-ssh-authentication-protocol]]（認証完了後に開始）、[[rfc4253-ssh-transport-layer]]
- 土台: [[rfc4251-ssh-architecture]]、[[rfc4250-ssh-assigned-numbers]]（§4.9 にチャネル型・要求名の初期割り当て）
- 更新: RFC 8308 → [[ssh-core-rfcs]]
- 既存の拡張例: OpenSSH の `hostkeys-00@openssh.com`（グローバル要求によるホスト鍵ローテーション通知）→ [[openssh-protocol-extensions]]

## 引用すべき箇所

> There are several kinds of requests that affect the state of the remote end globally, independent of any channels. [...] Note that both the client and server MAY send global requests at any time, and the receiver MUST respond appropriately.
> — RFC 4254, §4

> If the request is not recognized or is not supported for the channel, SSH_MSG_CHANNEL_FAILURE is returned.
> — RFC 4254, §5.4

## 自研究との関係

（※ここは解釈）

**「最も簡単に実装できるが、最も意味が薄い層」というのが読後の結論。**

実装の容易さは圧倒的。グローバル要求かチャネル要求として `attestation@example.com` を定義すれば、**OpenSSH のコードにメッセージ番号を 1 つも足さずに** attestation の往復が書ける。プロトタイプを最短で動かすならここ。

しかし本研究の主張としては成立しにくい。理由は 3 つ:

1. **時系列が逆。** この層が動くのは認証完了後。「接続を許可するか」の判断は既に済んでいる。attestation の結果で接続を拒否するには、**一度受け入れたセッションを切る**という形になり、「認証の意味を拡張する」という本研究の狙い（`docs/scope.md`）とずれる
2. **強制力がない。** 未対応の相手は失敗を返すだけ。それは段階的導入には都合がよいが、**攻撃者が「attestation に対応していないふり」をすれば素通りできる**ことも意味する。ダウングレード攻撃への耐性が構造的にない（KEX に載せた場合は `I_C`/`I_S` が exchange hash に入るので改竄が検出できる。→ [[rfc4253-ssh-transport-layer]] §8）
3. **束縛の手当てが自前になる。** session identifier への署名という既製の構造（[[rfc4252-ssh-authentication-protocol]] §7）がこの層にはない

**ただし使い道が 1 つある: 継続的な再 attestation。** §4 のグローバル要求は**双方向にいつでも送れる**。長時間セッションの途中でサーバが再検証を要求する、という用途はこの層が最も自然に書ける。[[draft-ietf-rats-reference-interaction-models]] の Streaming モデルを SSH に写すなら、初回は KEX 層、以後の再検証はグローバル要求、という組み合わせがありうる（rekey に相乗りする案は [[rfc4253-ssh-transport-layer]] §9 に書いた。どちらが良いかは未決）。

**論文での扱い**: 問い 1 の選択肢を列挙する際、この層を「実装は最も容易だが、認証判断より後になるため本研究の目的を満たさない」として除外する形で使う。除外理由が明確なので、設計判断の説得力を上げる材料になる。

## 未解決・気になる点

- §7 TCP/IP ポート転送は未読。**踏み台（ProxyJump）経由の attestation** を考えるときに関係する可能性がある。多段 SSH で「どのホストの状態を検証しているのか」は本研究の実運用上の論点になりうる
- §6.2〜6.10（pty、環境変数、シグナル、exit status）は本研究に無関係と判断してスキップ
- §11 Security Considerations が未読。エンドポイントセキュリティ、プロキシ転送、X11 転送の項目があるので、**転送機能が attestation の前提（測定された状態）を崩さないか**という観点では読む価値があるかもしれない
- グローバル要求で再 attestation を実装した場合、応答が要求と同じ順序で返る必要がある（§4）ことが並行処理の制約になるか
