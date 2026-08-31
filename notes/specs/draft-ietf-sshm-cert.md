---
id: "draft:ietf-sshm-cert-01"
title: "SSH Certificate Format"
body: "IETF"
status: "Active Internet-Draft (SSHM WG Document)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-ietf-sshm-cert/"
type: spec
tags: [ssh-certificate, sshm, critical-options, extensions, openssh, certkeys, damien-miller]
relevance: high
added: 2026-08-21
---

## 何を規定しているか

SSH で使う軽量な証明書形式の仕様。ユーザ認証とホスト認証の双方に使える。著者は **Damien Miller (OpenSSH)**、最新版 `-01`（2026-06-14）、SSHM WG 文書。

**OpenSSH が 2010 年から実装してきた独自形式（`PROTOCOL.certkeys`）を、IETF が事後的に標準化するもの。** ドラフト自身が「OpenSSH is the originating implementation of this protocol and has supported it since 2010」と述べる。libssh、Go の `crypto/ssh` など複数の実装が既に採用済み。

> **注**: OpenSSH のリポジトリ master ブランチから `PROTOCOL.certkeys` が消えている（2026-08-21 確認。raw / GitHub API のいずれでも 404。過去のコミット SHA 経由でのみ取得可能）。この I-D への移行に伴うものと推測されるが、**未確認**。以下の記述は commit `38e83e4f` 時点の `PROTOCOL.certkeys` に基づく。**I-D 本文（37 ページ）は未読。**

## 証明書の構造

nonce / public key / serial / type / key id / valid principals / valid after / valid before / **critical options** / **extensions** / reserved / signature key / signature

| フィールド | 内容 |
|---|---|
| nonce | CA が入れる乱数（16–32 バイト）。署名ハッシュへの衝突攻撃対策 |
| serial | CA が付ける任意の番号。未使用ならゼロ |
| type | `SSH_CERT_TYPE_USER` (1) / `SSH_CERT_TYPE_HOST` (2) |
| key id | CA が署名時に入れる自由書式テキスト。ログ用 |
| valid principals | ユーザ名（user 証明書）またはホスト名（host 証明書）。ゼロ長なら任意の principal に有効 |
| valid after / before | `valid after <= current time < valid before` で有効判定 |
| signature key | CA の公開鍵。**証明書の連鎖（chained certificates）は非対応** |

## 本研究に効く定義・要件 — critical options と extensions

**ここが本研究にとってこの仕様を読む理由。** 名前と値の組で、辞書順に並べる。両者の違いは**未知の項目に出会ったときの挙動**:

| | 未知の項目に出会ったとき | 性質 |
|---|---|---|
| **critical options** | **証明書ごと拒否する** | fail-closed |
| **extensions** | **無視する** | fail-open |

原文:

> All options are "critical", if an implementation does not recognise a option then the validating party should refuse to accept the certificate.
> — PROTOCOL.certkeys, Critical options

> If an implementation does not recognise an extension, then it should ignore it.
> — PROTOCOL.certkeys, Extensions

> Generally, critical options are used to control features that restrict access where extensions are used to enable features that grant access.
> — PROTOCOL.certkeys

### 独自項目の追加方法

> Custom options should append the originating author or organisation's domain name to the option name, e.g. "my-option@example.com".
> — PROTOCOL.certkeys

**つまり RFC も IANA 登録も要らずに独自項目を追加できる。** [[iana-ssh-registry-and-extension-points]] の Expert Review よりさらに軽い。

## 自研究との関係

（※ここは解釈）

### この二分法が中心的な問い 2（後方互換性）の答えそのもの

attestation Evidence を証明書に載せる場合、critical options と extensions の選択が**そのまま移行戦略になる**:

| 置き場所 | 古い実装の挙動 | 意味 |
|---|---|---|
| **extensions** | Evidence を**無視して接続を許す** | 段階的導入が可能。ただし**攻撃者は古い実装を装えば検証を回避できる**（downgrade） |
| **critical options** | Evidence を**理解できないので接続を拒否** | 検証を強制できる。ただし対応実装が揃うまで**互換性が壊れる** |

**この非対称性は本研究の設計判断として明示的に論じる価値がある。** おそらく答えは「両方定義して運用ポリシーで選ばせる」だが、その場合 downgrade 攻撃への対処を別途示す必要がある。

### ただし証明書方式には構造的限界がある

証明書は **CA が署名した時点の主張**でしかない。ホストの状態は起動後に変わるので、証明書に Evidence を焼き込む方式は:

- 発行時点と接続時点の間の TOCTOU を残す
- freshness を証明書の有効期限でしか担保できない（[[ssh-tpm-ca-authority-device-attested-certs]] が 5 分の短命証明書で回避を試みている方式）
- nonce によるチャレンジ・レスポンスができない

したがって**証明書方式は「軽い導入経路」ではあるが、freshness の要件（中心的な問い 4）を満たすには不十分**という論証になりそう。`SSH_MSG_EXT_INFO` 方式との比較で、この点が分岐になる。

### 「chained certificates 非対応」も効く

RATS では Endorser（TPM ベンダ）→ AK 証明書 → Evidence という証明書チェーンが自然に出てくる。SSH 証明書がチェーンを持てないなら、**EK/AK 証明書チェーンを SSH 証明書の中では表現できない**。別の運搬手段が要る。

## 未解決・気になる点

- **I-D 本文（37 ページ）が未読。** 上記は OpenSSH の `PROTOCOL.certkeys`（commit 固定版）に基づく。I-D で仕様が変わっている可能性がある
- `PROTOCOL.certkeys` が master から消えた理由の確認
- extensions フィールドの値のサイズ上限。TPM Quote が入るか
- host 証明書における extensions の既定値は何か（user 証明書の `permit-*` 系は判明済みだが host 側は未確認）
- `draft-vishwakarma-opsawg-ssh-cert-radius`（RADIUS Extension for Certificate-based SSH Authentication）— 未読、関連度不明
