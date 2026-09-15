---
id: "rfc:4251"
title: "The Secure Shell (SSH) Protocol Architecture"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4251"
type: spec
tags: [ssh, core-spec, architecture, host-keys, tofu, trust-model, man-in-the-middle, extensibility, data-types, rfc4251]
relevance: high
added: 2026-09-09
---

> 中核 5 本の全体像は [[ssh-core-rfcs]]（地図）を参照。本ノートは RFC 4251 単体の精読。
> **[[ssh-core-rfcs]] に残っていた宿題「RFC 4251 の Security Considerations は TOFU について何と書いているか」への回答を含む。**
> **2026-09-15: 研究テーマを「attestation をクライアント認証に拡張する」に改めたのに合わせ、§9.4 を精読して解釈を組み替えた。** 本研究の動機の一次出典は §9.4.4 / §9.4.6。TOFU を扱う §4.1 / §9.3.4 はサーバー認証側の話で、対比として使う。

## 何を規定しているか

SSH の**アーキテクチャ文書**（2006-01）。著者は T. Ylonen と C. Lonvick (Ed.)。3 層構造（Transport / User Authentication / Connection）、ホスト鍵の信頼モデル、拡張性の設計方針、データ型の表現、アルゴリズム命名規則、そして 14 ページに及ぶ Security Considerations を規定する。

具体的なパケット形式は一切定義せず、それらは RFC 4252 / 4253 / 4254 に分かれている。**本研究にとっては、SSH のクライアント認証が「端末が侵害されていないこと」を前提にしていると仕様自身の言葉で書いている文書**（§9.4.4, §9.4.6）。あわせて、サーバー認証側で TOFU を採った理由も説明している（§4.1, §9.3.4）。

## 本研究に効く定義・要件

### §4.1 Host Keys — TOFU の一次出典

ホスト鍵の信頼モデルとして 2 つを提示する:

| モデル | 内容 | 仕様が挙げる難点 |
|---|---|---|
| ローカル DB | クライアントがホスト名と公開鍵の対応表を持つ | 集中管理基盤も第三者調整も不要だが、**対応表の維持が負担になる** |
| CA による証明 | ホスト名と鍵の対応を CA が証明。クライアントは CA root だけ知る | 維持は楽だが、**各ホスト鍵を事前に中央権威が証明する必要があり、中央基盤に多くの信頼が置かれる** |

そのうえで、**第 3 の道として TOFU が明示的に許容されている**:

> The protocol provides the option that the server name - host key association is not checked when connecting to the host for the first time. This allows communication without prior communication of host keys or certification. The connection still provides protection against passive listening; however, it becomes vulnerable to active man-in-the-middle attacks. — §4.1

しかも**その理由まで書いてある**。「本執筆時点でインターネット上に広く配備された鍵基盤が存在しないため、そうした基盤が現れるまでの移行期間、この選択肢がプロトコルをはるかに使いやすくする」。さらに WG の判断として:

> The members of this Working Group believe that 'ease of use' is critical to end-user acceptance of security solutions, and no improvement in security is gained if the new solutions are not used. — §4.1

TOFU の具体的な実装戦略（初回は無検証で受け入れ、ローカル DB に保存し、以後比較する）も「可能な戦略の一例」として §4.1 に書かれている。**現在の `known_hosts` の振る舞いはここが出典**。

### §9.3.4 Man-in-the-middle — 仕様自身による限界の認定

宿題への答え。仕様は TOFU の危険性を**明確に、かつ強い言葉で**認めている。

> In summary, the use of this protocol without a reliable association of the binding between a host and its host keys is inherently insecure and is NOT RECOMMENDED. — §9.3.4

同節は MITM を 3 ケースに分けて論じる。第 1（セッション開始前に装置を挟む）、第 2（**サーバ公開鍵が安全に配布されていない場合**、ソーシャルエンジニアリングで偽鍵を掴ませられる）、第 3（確立後のパケット改竄——MAC が健全なら現実的でない）。いずれも**サーバー認証側**の問題で、本研究（クライアント認証への attestation）の対象ではない。

さらに、仕様は拡張による改善を予告している:

> Because the protocol is extensible, future extensions to the protocol may provide better mechanisms for dealing with the need to know the server's host key before connecting. — §9.3.4

例として挙がっているのは secure DNS 経由のフィンガープリント公開と、鍵交換時の Kerberos/GSS-API によるサーバ認証。**この一文はサーバーのホスト鍵についてのものなので、本研究の根拠として引くと誤引用になる。** 「SSH は拡張で認証を強化することを想定した設計である」という一般的な文脈でのみ使う。

### §9.4 Authentication Protocol — 本研究の動機の一次出典

ユーザ認証プロトコルの Security Considerations。まず前提として:

> The purpose of this protocol is to perform client user authentication. It assumes that this runs over a secure transport layer protocol, which has already authenticated the server machine, established an encrypted communications channel, and computed a unique session identifier for this session. — §9.4

認証方式の組み合わせはサーバーのローカルポリシーに委ねられ、`Authentication is no stronger than the weakest combination allowed.` とされる。

そして方式ごとの前提が明記されている:

| 節 | 方式 | 仕様が置いている前提 | 緩和策として仕様が挙げるもの |
|---|---|---|---|
| **§9.4.4** | `publickey` | **クライアントホストが侵害されていないこと**、およびサーバーのホスト秘密鍵が侵害されていないこと | 秘密鍵のパスフレーズ（ただし強制できない）。パスフレーズを強制可能にするスマートカード等 |
| §9.4.5 | `password` | サーバーが侵害されていないこと | 公開鍵認証など別の方式 |
| **§9.4.6** | `hostbased` | **クライアントが侵害されていないこと** | **他の認証方式との併用以外に緩和策はない** |

> The use of public key authentication assumes that the client host has not been compromised. It also assumes that the private key of the server host has not been compromised. — §9.4.4

> Host-based authentication assumes that the client has not been compromised. There are no mitigating strategies, other than to use host-based authentication in combination with another authentication method. — §9.4.6

**SSH のクライアント認証は、クライアント端末が侵害されていないことを「前提」として置き、それを検証する手段を持たない。** §9.4.4 が挙げる緩和策（パスフレーズ、スマートカード）は鍵の保護を強めるものであって、端末の状態を検証するものではない。

### §4.2 Extensibility — 拡張の設計思想

> We believe that the protocol will evolve over time, and some organizations will want to use their own encryption, authentication, and/or key exchange methods. Central registration of all extensions is cumbersome, especially for experimental or classified features. — §4.2

だから DNS 名を使った局所名前空間（`name@domainname`）を採る、という説明。**「実験的な機能のために中央登録を待たなくてよい」ことが設計意図として明記されている**——[[rfc4250-ssh-assigned-numbers]] の PRIVATE USE と対になる根拠。

同時に「基本プロトコルは可能な限り単純に保ち、必要なアルゴリズムは最小限に」という設計目標も述べている。attestation のような重い機構を足す提案は、この目標との緊張関係を自覚しておく必要がある。

### §6 Algorithm and Method Naming

アルゴリズム／方式の識別子は printable US-ASCII、非空、**64 文字以内**、case-sensitive。2 形式:

- `@` を含まない名前 → IETF CONSENSUS で割り当て。IANA 登録が必須
- `name@domainname` → 誰でも定義可。`@` は 1 個、後半は定義者が管理する FQDN

（[[rfc4250-ssh-assigned-numbers]] §4.6.1 と同一の規約。二重に書かれている）

### §5 Data Type Representations

`byte` / `boolean` / `uint32` / `uint64` / `string` / `mpint` / `name-list`。SSH の全メッセージはこの型で組み立てられる。**attestation Evidence（TPM Quote、イベントログ、証明書チェーン）を SSH メッセージに載せるなら `string`（長さ前置のバイト列）に詰めることになる。**

## 拡張点・自由度

- ホスト鍵の**検証方法そのものは規定していない**。§4.1 は「ローカル DB」「CA」「無検証」の 3 つを提示するだけで、どれを選ぶかも、どう実装するかも実装依存。`Implementations MAY provide additional methods for verifying the correctness of host keys` とあり、**新しい検証方法を足すことは仕様の範囲内**
- 鍵の配布基盤について `This protocol makes no assumptions or provisions for an infrastructure or means for distributing the public keys of hosts`（§9.3.4）と明言。**空白であることが明示されている**
- 局所名前空間の中身には関与しない（§4.2, §6）

## 他仕様との関係

- 分冊: RFC 4253（トランスポート層）、RFC 4252（ユーザ認証）、RFC 4254（コネクション）
- 番号と名前の IANA 表: [[rfc4250-ssh-assigned-numbers]]（§6/§7 と内容が重複）
- 更新: RFC 8308（拡張交渉）、9141 → [[ssh-core-rfcs]]
- 本研究の隣接: [[draft-ietf-sshm-cert]]（SSH 証明書形式）は §4.1 の「CA による証明」モデルの現代版

## 引用すべき箇所

**本研究の動機（クライアント認証）:**

> The use of public key authentication assumes that the client host has not been compromised.
> — RFC 4251, §9.4.4

> Host-based authentication assumes that the client has not been compromised. There are no mitigating strategies, other than to use host-based authentication in combination with another authentication method.
> — RFC 4251, §9.4.6

> Authentication is no stronger than the weakest combination allowed.
> — RFC 4251, §9.4

**対比（サーバー認証側の TOFU）:**

> The protocol provides the option that the server name - host key association is not checked when connecting to the host for the first time. [...] it becomes vulnerable to active man-in-the-middle attacks.
> — RFC 4251, §4.1

> In summary, the use of this protocol without a reliable association of the binding between a host and its host keys is inherently insecure and is NOT RECOMMENDED. However, it may be necessary in non-security-critical environments, and will still provide protection against passive attacks.
> — RFC 4251, §9.3.4

> This protocol makes no assumptions or provisions for an infrastructure or means for distributing the public keys of hosts.
> — RFC 4251, §9.3.4

> Because the protocol is extensible, future extensions to the protocol may provide better mechanisms for dealing with the need to know the server's host key before connecting.
> — RFC 4251, §9.3.4

> The members of this Working Group believe that 'ease of use' is critical to end-user acceptance of security solutions, and no improvement in security is gained if the new solutions are not used.
> — RFC 4251, §4.1

## 自研究との関係

（※ここは解釈）

**論文の Introduction の問題設定は §9.4.4 と §9.4.6 で立つ。** 仕様自身が「`publickey` 認証はクライアントホストが侵害されていないことを前提にする」「`hostbased` 認証には他方式との併用以外の緩和策がない」と書いている。つまり SSH のクライアント認証は、端末の完全性を**検証する対象ではなく前提**として扱っている。本研究はこの前提を、server の challenge と client の attestation response によって**検証可能な主張に置き換える**提案として位置づけられる。

**§9.4.4 の緩和策との差分が、そのまま貢献の説明になる。** 仕様が挙げるのはパスフレーズとスマートカードで、どちらも「鍵を盗まれにくくする」対策である。攻撃者が端末を改竄して正規ユーザのセッションに相乗りする場合や、改竄された `ssh` / `ssh-agent` が鍵を悪用する場合には効かない。attestation は「鍵を使っている端末がいま期待した状態か」を検証するので、**緩和策の軸が違う**と論じられる。

**§9.4 の前提文も効く。** ユーザ認証は「サーバー認証済みで、session identifier が計算済みのトランスポートの上で動く」と明記されている。client の Evidence を session identifier に束縛する設計（[[rfc4252-ssh-authentication-protocol]] §7 の署名対象と同じ構造）は、この前提をそのまま使える。

**§4.1 / §9.3.4 の TOFU の議論は対比として使う。** サーバー認証側では仕様が `inherently insecure and is NOT RECOMMENDED` と認め、TOFU を採った理由を「鍵基盤が存在しないから」と説明している。「SSH は認証の両側で鍵の所持しか見ていない。サーバー側の弱点は広く議論されてきたが、クライアント側の前提（§9.4.4）は検証されないまま残っている」という対比を Introduction に置ける。**ただし §9.3.4 の "future extensions" はサーバーのホスト鍵についての一文なので、本研究の直接の根拠として引かないこと。**

**§4.1 の WG 声明は本研究にも跳ね返る。** 「使われない解決策では安全性は向上しない」という一文は、TPM 前提・Reference Value 管理が必要な提案にそのまま当てはまる。問い 2（後方互換性・段階的導入）と問い 5（大規模運用時のコスト）は、この一文への回答として書くべきものだと思う。クライアント認証側では、`partial success` による多段認証（[[rfc4252-ssh-authentication-protocol]] §5.1）で「attestation を要求するユーザだけに段階的に適用する」形が取れるので、この点はサーバー認証側より論じやすい。

**信頼モデルの位置づけ。** 既存のクライアント認証が「鍵と利用者の対応」を検証するのに対し、attestation は「鍵と端末の状態の対応」を検証する。§4.1 の CA モデルの難点として挙がる「中央基盤に多くの信頼が置かれる」は、RATS の Verifier 配置（問い 3）でも同じ問題として再来する。

## 未解決・気になる点

- ~~§9.4.4 Public Key Authentication、§9.4.6 Host-Based Authentication は未読~~ → **2026-09-15 精読済み**（上記 §9.4 の節）。§9.5 Connection Protocol（エンドポイントセキュリティ、プロキシ転送、X11 転送）はまだ未読
- RFC 9141 が RFC 4251 の何を更新したか（[[ssh-core-rfcs]] からの積み残し）
- §5 のデータ型のうち、**大きなバイナリ（TPM Quote、イベントログ）を運ぶときのサイズ制約**。RFC 4253 §6.1 の最大パケット長（32768 バイト以上を受け入れること）との関係を要確認 → [[rfc4253-ssh-transport-layer]]
- §4.5 Localization、§9.2 Control Character Filtering は本研究に無関係と判断してスキップした
