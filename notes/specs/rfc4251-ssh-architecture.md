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

## 何を規定しているか

SSH の**アーキテクチャ文書**（2006-01）。著者は T. Ylonen と C. Lonvick (Ed.)。3 層構造（Transport / User Authentication / Connection）、ホスト鍵の信頼モデル、拡張性の設計方針、データ型の表現、アルゴリズム命名規則、そして 14 ページに及ぶ Security Considerations を規定する。

具体的なパケット形式は一切定義せず、それらは RFC 4252 / 4253 / 4254 に分かれている。**本研究にとっては「なぜ SSH のホスト認証が TOFU なのか」を仕様自身の言葉で説明している唯一の文書**。

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

同節は MITM を 3 ケースに分けて論じる。第 1（セッション開始前に装置を挟む）、第 2（**サーバ公開鍵が安全に配布されていない場合**、ソーシャルエンジニアリングで偽鍵を掴ませられる）、第 3（確立後のパケット改竄——MAC が健全なら現実的でない）。**第 2 ケースこそが本研究の対象**である。

そして次の一文が、本研究を仕様の延長線上に位置づける根拠になる:

> Because the protocol is extensible, future extensions to the protocol may provide better mechanisms for dealing with the need to know the server's host key before connecting. — §9.3.4

例として挙がっているのは secure DNS 経由のフィンガープリント公開と、鍵交換時の Kerberos/GSS-API によるサーバ認証。**attestation はここに並ぶ第 3 の答えとして提案できる。**

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

**宿題の答えは「はっきり引ける」。** [[ssh-core-rfcs]] に残っていた「仕様自身が TOFU の限界を認めていると引けるか」は、§9.3.4 の `inherently insecure and is NOT RECOMMENDED` で決着する。しかも §4.1 は TOFU を採った理由まで自白している——**「鍵基盤が存在しないから」であって、「これで十分だから」ではない**。論文の Introduction はこの 2 つを並べるだけで問題設定が完成する。

**さらに強いのは §9.3.4 の "future extensions" の一文。** 仕様自身が「拡張によってより良い機構が提供されうる」と述べ、その例として secure DNS と Kerberos/GSS-API を挙げている。本研究は**この列に attestation を加える提案**として位置づけられる。「仕様の想定外のことをしている」のではなく「仕様が予告した空白を埋めている」と言える。これは査読でも IETF でも通りやすい構図。

**ただし §4.1 の WG 声明は諸刃。** 「使われない解決策では安全性は向上しない」という一文は、**本研究の提案にもそのまま跳ね返る**。TPM 前提・Reference Value 管理が必要な仕組みは、TOFU より確実に使いにくい。問い 2（後方互換性・段階的導入）と問い 5（大規模運用時のコスト）は、この一文への回答として書くべきものだと思う。「ease of use を損なわずに TOFU を置き換える」という枠で論じると、仕様の価値判断と整合する。

**信頼モデルの位置づけ。** §4.1 の 2 モデル（ローカル DB / CA）に対し、attestation は**第 3 のモデル**を提案することになる——「鍵と名前の対応」ではなく「鍵とマシンの状態の対応」を検証する。この対比は Background の構成にそのまま使える。なお §4.1 の CA モデルの難点として挙がる「中央基盤に多くの信頼が置かれる」は、RATS の Verifier 配置（問い 3）でも同じ問題として再来する。

## 未解決・気になる点

- §9.4.4 Public Key Authentication、§9.4.6 Host-Based Authentication は未読。クライアント→サーバ方向の attestation を設計するうえで、既存のユーザ認証がどんな脅威を想定しているかは押さえるべき
- RFC 9141 が RFC 4251 の何を更新したか（[[ssh-core-rfcs]] からの積み残し）
- §5 のデータ型のうち、**大きなバイナリ（TPM Quote、イベントログ）を運ぶときのサイズ制約**。RFC 4253 §6.1 の最大パケット長（32768 バイト以上を受け入れること）との関係を要確認 → [[rfc4253-ssh-transport-layer]]
- §4.5 Localization、§9.2 Control Character Filtering は本研究に無関係と判断してスキップした
