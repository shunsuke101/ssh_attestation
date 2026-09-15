---
id: "rfc:8308"
title: "Extension Negotiation in the Secure Shell (SSH) Protocol"
body: "IETF"
status: "Proposed Standard"
year: 2018
url: "https://www.rfc-editor.org/info/rfc8308"
type: spec
tags: [ssh, ext-info, extension-negotiation, kexinit, server-sig-algs, extension-names, rfc8308, rfc9519]
relevance: high
added: 2026-09-15
---

> レジストリ全体と登録ポリシーは [[iana-ssh-registry-and-extension-points]]、中核 5 本の地図は [[ssh-core-rfcs]]。本ノートは RFC 8308 単体の精読。
> **[[iana-ssh-registry-and-extension-points]] に残っていた宿題 2 件（`SSH_MSG_EXT_INFO` の送信タイミングとサイズ上限）への回答を含む。**

## 何を規定しているか

SSH に**拡張交渉の仕組み**を後付けする Standards Track RFC（2018-03）。著者は D. Bider（Bitvise Limited）。RFC 4251 / 4252 / 4253 / 4254 をすべて更新し、のちに RFC 9519 に更新された。

動機は RFC 4253 に拡張交渉がなかったこと:

> The original design of the SSH transport layer [RFC4253] lacks proper extension negotiation. Meanwhile, diverse implementations take steps to ensure that known message types contain no unrecognized information. This makes it difficult for implementations to signal capabilities and negotiate extensions without risking disconnection. — §1

直接のきっかけは RSA/SHA-2 署名（RFC 8332）の導入で、クライアントが「サーバがどの公開鍵アルゴリズムを受け付けるか」を試行錯誤なしに知る必要があった。

機構は 2 段:

1. 最初の `SSH_MSG_KEXINIT` の `kex_algorithms` に**疑似アルゴリズム名**（`ext-info-c` / `ext-info-s`）を入れて対応を表明する
2. 鍵交換の後、暗号化された **`SSH_MSG_EXT_INFO`**（番号 7）で「拡張名と値」の組を送る

## 本研究に効く定義・要件

### §2.1 KEXINIT への表明 — 疑似アルゴリズム名という手口

- サーバは `ext-info-s`、クライアントは `ext-info-c` を `kex_algorithms` のどこかに入れる (MUST)。**最初の鍵交換でのみ**
- `kex_algorithms` を選んだ理由: `SSH_MSG_KEXINIT` の name-list のうち**方向ごとの複製がない** 2 つのうちの 1 つだから
- クライアントとサーバで名前を変えてあるのは、**互いに一致せず、鍵交換方式の選択に影響しない**ようにするため
- 万一 `ext-info-c` / `ext-info-s` が鍵交換方式として合意されたら、双方は切断しなければならない (MUST)

**この手口の含意は大きい。** KEXINIT のペイロードは丸ごと exchange hash H に入る（[[rfc4253-ssh-transport-layer]] §8）。したがって**「私は拡張 X に対応している」という表明は、ホスト鍵署名によって改竄から守られる**。能力表明を削ってダウングレードさせる攻撃は検出される。

### §2.2 有効化の条件

- `ext-info-c` / `ext-info-s` を送った側は、相手からの `SSH_MSG_EXT_INFO` を受け付ける準備がなければならない (MUST)
- 表明を受け取った側は `SSH_MSG_EXT_INFO` を送って**よい (MAY)** が、義務ではない
- 相手の KEXINIT を待たずに表明を決めてよい

### §2.3 `SSH_MSG_EXT_INFO` の形式

```
byte       SSH_MSG_EXT_INFO (value 7)
uint32     nr-extensions
repeat "nr-extensions" times:
  string   extension-name
  string   extension-value (binary)
```

**値は任意のバイナリ**。

### §2.4 送信タイミング — 宿題 1 への回答

| 送り手 | 送れる時点 | 規範 |
|---|---|---|
| **クライアント** | **最初の `SSH_MSG_NEWKEYS` の直後の 1 パケットのみ** | 送るなら**必ずここ** (MUST) |
| サーバ（第 1 の機会） | 最初の `SSH_MSG_NEWKEYS` の直後 | MAY |
| サーバ（第 2 の機会） | `SSH_MSG_USERAUTH_SUCCESS` の**直前** | MAY。第 1 の機会に送ったかどうかに関係なく送れる。**送った場合は第 1 の内容を置き換える** |

> If a client sends SSH_MSG_EXT_INFO, it MUST send it as the next packet following the client's first SSH_MSG_NEWKEYS message to the server. — §2.4

サーバの第 2 の機会がある理由: 「未認証のクライアントには明かしたくない拡張を、認証後に明かせるようにするため」。

**時系列を整理するとこうなる**（`[[ ]]` 内が EXT_INFO を置ける位置）:

```
KEXINIT ⇄ KEXINIT          ← ext-info-c / ext-info-s を表明（H に入る）
KEX（DH 等）               ← サーバがホスト鍵で H に署名、クライアントがホスト鍵を検証（TOFU の地点）
NEWKEYS ⇄ NEWKEYS
[[ C→S: EXT_INFO ]]         ← クライアント唯一の機会
[[ S→C: EXT_INFO ]]         ← サーバ第 1 の機会
SERVICE_REQUEST "ssh-userauth"
USERAUTH_REQUEST ...
[[ S→C: EXT_INFO ]]         ← サーバ第 2 の機会
USERAUTH_SUCCESS
```

### §2.5 未知の拡張の扱い — 段階的導入の保証

> Applications MUST ignore unrecognized extension-names. — §2.5

> Applications that do not implement or recognize an extension MUST ignore its extension-value, regardless of its size or content. Applications MUST tolerate any sequence of bytes -- including null bytes at any position -- in an unknown extension's extension-value. — §2.5

拡張ごとに「両者が送って初めて有効」か「片方だけで有効」かを決めてよい。拡張の並び順は無視しなければならない。

### §2.5 サイズ上限 — 宿題 2 への回答

> The cumulative size of an SSH_MSG_EXT_INFO message is limited only by the maximum packet length that an implementation may apply in accordance with [RFC4253]. Implementations MUST accept well-formed SSH_MSG_EXT_INFO messages up to the maximum packet length they accept. — §2.5

**拡張値自体に固有の上限はない。上限は RFC 4253 §6.1 のパケット長だけ**＝全実装が保証するのは非圧縮ペイロード 32768 バイトまで（→ [[rfc4253-ssh-transport-layer]]）。TPM Quote（数百バイト）は余裕、イベントログは入らない可能性が高い。

### §3 初期定義の 4 拡張

| 拡張名 | 送り手 | 内容 |
|---|---|---|
| `server-sig-algs` | サーバ | `publickey` 認証で受け付ける公開鍵アルゴリズムの一覧。**実装すべき (SHOULD)** |
| `delay-compression` | 双方 | 鍵再交換なしで圧縮方式を再交渉。新メッセージ `SSH_MSG_NEWCOMPRESS`（番号 8）を導入 |
| `no-flow-control` | 双方 | チャネルのフロー制御を無効化（単一チャネルのファイル転送向け） |
| `elevation` | クライアント | Windows の管理者権限昇格の要否。結果は**グローバル要求**で返す |

`elevation` は「EXT_INFO で希望を伝え、結果を後から RFC 4254 のグローバル要求で返す」という**層をまたぐ組み合わせの前例**になっている。

§3.2.3 には実装上の落とし穴も記録されている: **OpenSSH 7.5 以前のクライアントは EXT_INFO 受信を表明しながら、null バイトを含む拡張値を受け取ると切断する**（7.6 で修正）。「未知の値を許容せよ」という規範が実装で破られていた実例。

### §4 IANA — 拡張名レジストリの新設

- メッセージ番号 7（`SSH_MSG_EXT_INFO`）と 8（`SSH_MSG_NEWCOMPRESS`）を追加
- 鍵交換方式名レジストリに `ext-info-s` / `ext-info-c` を追加
- **"Extension Names" レジストリを新設**。名前は RFC 4250 §4.6.1 の規約に従う。`@` を含まない名前の新規登録は、RFC 8308 の時点では **IETF Review**

**RFC 9519（2024-01）がこれを Expert Review に緩和した**（一次情報で確認済み）:

> The only IANA SSH protocol parameter registries not affected are "Message Numbers" and "Publickey Subsystem Status Codes", as these remain Standards Action due to their limited resources as one-byte registry values. — RFC 9519, §2

## 拡張点・自由度

- **拡張名と拡張値の中身は完全に自由**。`name@domain` 形式なら登録不要、それ以外も現在は Expert Review で済む
- 拡張が有効になる条件（片側／双方）も拡張ごとに決めてよい（§2.5）
- 拡張の効果を後続のどの層で発揮させるかも自由（`elevation` がグローバル要求を使う前例）

**規定上の制約**:

- EXT_INFO を送れるのは**最初の鍵交換の後だけ**。表明（§2.1）も「最初の鍵交換」に限られる。**鍵再交換のたびに送り直す仕組みはない**
- クライアントの送信機会は 1 回だけ（§2.4）
- サイズは RFC 4253 のパケット長に縛られる（§2.5）
- EXT_INFO の**中身そのものは H に入らない**（入るのは KEXINIT 内の表明だけ）。中身は NEWKEYS 後の暗号化と MAC で守られる

## 他仕様との関係

- 更新対象: [[rfc4251-ssh-architecture]], [[rfc4252-ssh-authentication-protocol]], [[rfc4253-ssh-transport-layer]], [[rfc4254-ssh-connection-protocol]]
- 名前の規約: [[rfc4250-ssh-assigned-numbers]] §4.6.1
- 更新元: RFC 9519（登録ポリシーを Expert Review に）→ [[iana-ssh-registry-and-extension-points]]
- 動機となった仕様: RFC 8332（RSA/SHA-2 署名、同じ著者・同じ月）
- レジストリ全体: [[iana-ssh-registry-and-extension-points]]

## 引用すべき箇所

> The original design of the SSH transport layer [RFC4253] lacks proper extension negotiation. [...] This makes it difficult for implementations to signal capabilities and negotiate extensions without risking disconnection.
> — RFC 8308, §1

> If a client sends SSH_MSG_EXT_INFO, it MUST send it as the next packet following the client's first SSH_MSG_NEWKEYS message to the server.
> — RFC 8308, §2.4

> Applications that do not implement or recognize an extension MUST ignore its extension-value, regardless of its size or content.
> — RFC 8308, §2.5

> The cumulative size of an SSH_MSG_EXT_INFO message is limited only by the maximum packet length that an implementation may apply in accordance with [RFC4253].
> — RFC 8308, §2.5

## 自研究との関係

（※ここは解釈）

**本研究の方向（Attester = SSH クライアント、Verifier / Relying Party = SSH サーバ）にとって、クライアントの EXT_INFO は位置だけ見ればちょうどよい。**（ただし下で述べる通り、server challenge の往復が無いので Evidence の運搬路としては研究テーマと合わない）

- 鍵交換の直後、**ユーザ認証が始まる前**に届く。サーバは「このクライアントを認証フェーズに進ませるか」を Evidence を見てから決められる
- NEWKEYS の後なので**暗号化されている**。Evidence（PCR 値、ファームウェア版）の受動的な盗聴を防げる
- 能力表明（`ext-info-c` と、それと並べる attestation 用の疑似アルゴリズム名）は H に入るので**ダウングレードを検出できる**
- 未対応のサーバは拡張を黙って無視する（§2.5）。**既存サーバとの接続が壊れない**

**ただし freshness の設計に固有の制約が 1 つある。** クライアントの EXT_INFO は NEWKEYS の直後の 1 パケットに限られるので、**サーバから専用の challenge を受け取ってから Evidence を作る往復が入らない**。この時点でクライアントが使えるサーバ由来の予測不能な値は、**鍵交換そのもの**——サーバ KEXINIT の cookie と DH の `f` が入った H だけである。

つまり EXT_INFO に載せる設計は、RATS の Challenge/Response（→ [[draft-ietf-rats-reference-interaction-models]]）を「**鍵交換を challenge とみなす 1 往復版**」として実現することになる。これは [[rfc4253-ssh-transport-layer]] に書いた「H を Handle として使えるか」という論点と完全に一致する。**EXT_INFO を選ぶなら、その論証から逃げられない。** 研究テーマは「server からの challenge によって freshness を担保する」と明示しているので、**challenge の往復を持たない EXT_INFO は Evidence の運搬路としてはテーマと合わない**。明示的な server challenge を送れるのはユーザ認証層の新方式（サーバが 60–79 番で challenge を送れる → [[rfc4252-ssh-authentication-protocol]]）である。**問い 1 と問い 4 はここで結びつく。**

**EXT_INFO の現実的な役割は「能力表明」。** client が attestation 対応を表明し、server が対応する認証方式を提示する、という交渉部分に使える。KEXINIT 内の表明が H に入るのでダウングレード検出にも効く。

**TPM 側のサイズ制約も効く。** H を TPM の `qualifyingData` にそのまま入れられるかは、KEX 方式のハッシュ長と TPM が実装する最大ハッシュ長の組み合わせで決まる（→ [[tcg-tpm2-library-v185]]）。

**継続的な再 attestation には使えない。** EXT_INFO は最初の鍵交換の後にしか送れず、rekey のたびに送り直す仕組みがない。長時間セッション中の再検証は別の手段（グローバル要求など → [[rfc4254-ssh-connection-protocol]]）が要る。§3.4 `elevation` の「EXT_INFO で表明し、結果は後からグローバル要求で返す」という組み合わせは、初回 attestation と再 attestation を層で分ける設計の前例として参考になる。

**サーバの第 2 の機会（`USERAUTH_SUCCESS` 直前）は本研究では使い道が薄い。** サーバ→クライアント方向に Attestation Result を返す用途なら考えられるが、クライアント側に判断を委ねる場面は本研究の構成にない。

## 未解決・気になる点

- **EXT_INFO は最初の鍵交換後にしか送れない**という制約について、OpenSSH が後から独自拡張で緩めていないか未確認（`PROTOCOL` ファイルを当たる → [[openssh-protocol-extensions]]）。本ノートでは RFC 8308 の本文にない拡張には触れていない
- 現在の Extension Names レジストリに何が登録されているか未取得（→ [[iana-ssh-registry-and-extension-points]]）
- RFC 8308 の errata の有無を確認していない
- §3.2.3 の OpenSSH 7.5 問題のように、**「未知の値を無視せよ」が実装で守られていない例が他にもある可能性**。attestation 拡張の値はバイナリ（TPM 構造体）なので、古い実装との相互運用試験が要る
- クライアント EXT_INFO の直後にサーバが第 1 の機会で EXT_INFO を返すとき、それを「Evidence を受け取った」という応答に使えるか。§2.4 はサーバの第 1 の機会の送信を「サーバ自身の NEWKEYS の直後」と定めており、クライアントの EXT_INFO を受け取ってから返すという順序は保証されない
