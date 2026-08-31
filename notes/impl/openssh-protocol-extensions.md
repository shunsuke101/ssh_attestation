---
id: "url:https://github.com/openssh/openssh-portable/blob/master/PROTOCOL"
title: "OpenSSH PROTOCOL — vendor extensions to the SSH protocol"
project: "OpenSSH"
version: "master（2026-08-21 取得）"
language: "C"
license: "BSD 系（OpenSSH ライセンス）"
url: "https://github.com/openssh/openssh-portable/blob/master/PROTOCOL"
type: impl
tags: [openssh, protocol-extensions, session-bind, hostkeys-prove, ext-info, fido, u2f, attestation, channel-binding]
relevance: high
added: 2026-08-21
---

> OpenSSH の `PROTOCOL`, `PROTOCOL.u2f`, `PROTOCOL.agent` の 3 ファイルを横断してまとめたノート。
> **de facto 標準としての SSH が実際に何をしているか**の一次情報。

## 何が実装されているか

OpenSSH が独自に定義した SSH プロトコル拡張の一覧。名前はすべて `@openssh.com` サフィックス付き（[[draft-ietf-sshm-cert]] にある「独自項目には組織のドメイン名を付ける」慣行）。

## 本研究に直接効く 4 つの前例

### 1. Private Use 範囲を実際に使っている

**`SSH2_MSG_PING` = 192 / `SSH2_MSG_PONG` = 193。** IANA レジストリの「192–255 Reserved for Private Use (local extensions)」を OpenSSH 自身が使っている（→ [[iana-ssh-registry-and-extension-points]]）。

**本研究のプロトタイプ実装は、この範囲で堂々と実験できる。** IANA 登録も RFC も不要。前例があるので査読でも防御できる。

### 2. `session-bind@openssh.com` — SSH における channel binding の実例

`PROTOCOL.agent` より。**agent の接続を特定の SSH セッション識別子に束縛し、ホスト鍵による初回鍵交換の署名を使って検証する。** 後から destination constraints を判定するために使う。

**これは SSH で「何かをセッションに暗号学的に束縛する」既存の設計そのもの。** 中心的な問い 4（freshness / 再生防止）で、attestation Evidence をセッションに束縛する方式を設計するとき、**新規発明ではなく既存機構の拡張として位置づけられる。**

関連して `restrict-destination-v00@openssh.com`（鍵を特定の送信元・宛先ホスト／ユーザに制限）、`associated-certs-v00@openssh.com`（PKCS#11 トークンの証明書と秘密鍵の関連付け）。

### 3. `hostkeys-00@openssh.com` / `hostkeys-prove-00@openssh.com`

**認証後のホスト鍵の更新とローテーション。** ホストが「この鍵も自分のものだ」と**証明**する仕組みが既にある。

ホストが認証後に追加の主張を行い、それをクライアントが検証するという**フローの前例**。attestation Evidence を認証後に送る設計（passport モデル寄り）を考えるとき、このメッセージ交換の形を流用できる可能性がある。

### 4. `publickey-hostbound-v00@openssh.com`

ユーザ、サーバの識別子、セッションを束縛する公開鍵認証。ユーザ認証層での束縛の前例。

### その他の関連拡張

- **Strict key exchange extension** — Terrapin 攻撃対策。KEX を触る近年の前例（→ `draft-ietf-sshm-strict-kex`）
- **`ext-info-in-auth@openssh.com`** — 認証の途中で `SSH_MSG_EXT_INFO` を送れるようにする。RFC 8308 のタイミング制約を OpenSSH が緩めている
- `eow@openssh.com`, `no-more-sessions@openssh.com`, `tun@openssh.com`, streamlocal 系, `INFO@openssh.com`, SFTP 拡張多数

## OpenSSH における attestation の現状（`PROTOCOL.u2f`）

**ここが本研究にとって決定的な事実。**

OpenSSH は FIDO/U2F セキュリティキー（`sk-ecdsa-sha2-nistp256@openssh.com`, `sk-ssh-ed25519@openssh.com` とその証明書版）に対応しており、**attestation の概念は既に SSH に入っている。** ただし扱いは限定的:

> the protocol required for this proof is not privacy-preserving and may be used to identify U2F tokens with at least manufacturer and batch number granularity
> — PROTOCOL.u2f

> we choose not to include this information in the public key or save it by default
> — PROTOCOL.u2f

> OpenSSH optionally allows retaining the attestation information at the time of key generation.
> — PROTOCOL.u2f

> **OpenSSH treats the attestation certificate and enrollment signatures as opaque objects and does no interpretation of them itself.**
> — PROTOCOL.u2f

## 自研究との関係

（※ここは解釈）

### 最後の引用が論文の核になりうる

**「OpenSSH は attestation データを opaque object として扱い、一切解釈しない」** — これは、SSH における attestation の現状を一次情報で正確に言い切れる一文。

つまり現在の SSH は:

1. attestation データを**運ぶ**ことはできる（enrollment 時に保存できる）
2. しかし**検証しない**（Verifier が存在しない）
3. しかも対象は**クライアント側の鍵がハードウェア由来か**であって、**ホストの状態**ではない

`/collect` で見つけた OpenSSH 10.0 のリリースノート「a work-in-progress tool to verify FIDO attestation blobs」と合わせると、**OpenSSH は運搬はできるが検証は未着手、という状態**が確認できる。

これは本研究の Introduction で「SSH に attestation は部分的に存在するが、それは RATS の意味での attestation ではない」と述べる根拠になる。

### プライバシーの論点が既に SSH コミュニティで認識されている

`PROTOCOL.u2f` は attestation のプライバシー問題（製造者・バッチ単位でトークンが識別できる）を理由に、**既定で attestation を保存しない**という設計判断を下している。

**ホスト attestation を提案するとき、同じ反論が来る。** DAA（→ `draft-ietf-rats-daa`）や Privacy CA を設計に組み込んでおく必要がある。OpenSSH が既にこの理由で機能を絞っている以上、プライバシーへの回答なしに提案は通らない。

### 借用できる部分

- Private Use メッセージ番号（192–255）でのプロトタイプ実装
- `session-bind@openssh.com` のセッション束縛の設計
- `hostkeys-prove-00@openssh.com` のホストによる事後証明のフロー
- `@openssh.com` 方式の命名規約（標準化前の実験に使える）

### この実装が**やっていない**こと（＝貢献余地）

1. ホスト側の platform attestation が一切ない
2. attestation データの**解釈・検証**がない（opaque 扱い）
3. Reference Value / Appraisal Policy の概念がない
4. TOFU はそのまま

## 動かすなら

**未検証。** ソースの `PROTOCOL*` ファイルを読んだのみ。実際の挙動確認には OpenSSH のビルドと FIDO トークン（または `sk-dummy` 系のテストヘルパ）が要る。

## 未解決・気になる点

- `ssh-keygen -O write-attestation=` で保存される attestation blob の実際の形式
- OpenSSH 10.0 の「work-in-progress tool to verify FIDO attestation blobs」の現状（10.5 時点でどうなったか）
- `session-bind@openssh.com` の束縛の暗号学的な強度（何に対する署名か）
- `PROTOCOL.certkeys` が master から消えている件（→ [[draft-ietf-sshm-cert]]）
