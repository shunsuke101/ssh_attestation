---
id: draft:gutmann-ssh-preauth-06
title: "A Pre-Authentication Mechanism for SSH"
body: "IETF"
status: "Internet-Draft (individual submission, not a WG document)"
year: 2026
url: "https://datatracker.ietf.org/doc/draft-gutmann-ssh-preauth/"
type: spec
tags: [ssh, identification-string, pre-authentication, backward-compatibility, challenge-response, extension-point]
relevance: high
added: 2026-09-14
---

## 何を規定しているか

インターネットに晒された SSH 機器が受け続けるスキャン・探索攻撃を減らすための、**SSH プロトコル自体を一切変更しない** pre-authentication 機構。サーバが SSH の identification string（`SSH-2.0-...`）の Comment 欄に challenge を載せ、クライアントが同じく Comment 欄に response を返す。事前共有の `preAuthSecret` を知らない相手には、SSH のプロトコルメッセージを一切通さない。Peter Gutmann（University of Auckland）による個人 I-D で、SSHM WG の Related Internet-Drafts 欄に載っている。

## 本研究に効く定義・要件

この仕様のうち自分の設計に効くのは、**attestation とは無関係な部分**、すなわち「SSH のどこに追加データを流せるか」という一点。

| 節 | 内容 | どう使うか |
|---|---|---|
| 機構の配置 | identification string 交換（RFC 4253 §4.2）の Comment 欄を使う。プロトコル交渉より前の段階 | SSH の**最初期**に追加データを載せられる枠があることの実証。KEXINIT より前 |
| 書式 | サーバ `C=<challenge>`、クライアント `R=<response>`。「MUST be the first values in the Comment field, with any further entries that follow separated by a comma」 | カンマ区切りで**複数の拡張が同じ Comment 欄に共存できる**設計。ここが重要 |
| challenge | 64 bit の nonce を base64 で 11 文字（パディング無し）に符号化 | Comment 欄に載せられる実用的なサイズ感の目安 |
| response | `key = SHA256(challenge ‖ preAuthSecret)` / `response = base64(HMAC-SHA256(key, challenge)[0:7])` | 鮮度は challenge の nonce のみに依存する。セッション束縛は無い |
| 後方互換 | 未実装の実装は Comment 欄の値を無視して通常どおり動作する | **プロトコル番号も拡張交渉も使わずに済む**後方互換の型 |

## 拡張点・自由度

- identification string の Comment 欄は RFC 4253 §4.2 で自由記述が許されている枠であり、**IANA 登録も拡張交渉（RFC 8308 の EXT_INFO）も要らない**。このドラフトはその枠を実際に使ってみせた最初の具体例。
- ただし容量は厳しい。RFC 4253 §4.2 は identification string 全体を CR LF 込みで 255 バイト以内と定めている。`SSH-2.0-OpenSSH_10.5 ` の部分を引くと実質的に使えるのは 200 バイト強しかない。**TPM の Quote（署名込みで数百バイト〜）をここに載せるのは無理**で、載せられるのは「attestation に対応している」という宣言と nonce 程度。
- したがって自研究にとっての現実的な使い道は、**Evidence 本体の運搬路ではなく、(a) ケイパビリティ宣言、(b) サーバからクライアントへの challenge nonce の先出し** の 2 つ。特に (b) は、Evidence 生成を鍵交換と並行して始められるので問い 5（レイテンシ）に効く。

## 他仕様との関係

- 参照している: RFC 4253（identification string の書式）、RFC 4251
- 参照されている: unknown（個人 I-D で、他文書からの参照は確認していない）
- 競合・重複する仕様: 拡張交渉という意味では RFC 8308（EXT_INFO）と目的が重なるが、**EXT_INFO は鍵交換の後**にしか流せない。この I-D は鍵交換より前という点で埋めている枠が違う。`notes/specs/iana-ssh-registry-and-extension-points.md` の拡張点の一覧にこの枠を追記すること。

## 引用すべき箇所

> a simple pre-authentication mechanism that limits these attacks with minimal changes to SSH implementations and no changes to the SSH protocol itself — abstract

> Devices running SSH are frequently exposed on the Internet...making them vulnerable to the constant 3-degree background radiation of scanning and probing attacks. — abstract

> MUST be the first values in the Comment field, with any further entries that follow separated by a comma.

（※ `https://www.ietf.org/archive/id/draft-gutmann-ssh-preauth-06.txt` は 404 で、datatracker の文書ページ経由で本文を読んだ。**節番号は未確認。** 正式に引用する前に本文の節番号を確認すること）

## 未解決・気になる点

- この I-D は **attestation にも TPM にも一切言及していない**。自分が引くのは「SSH のどこに追加データを載せられるか」という設計上の先例としてであり、内容的な関連ではない。Related Work ではなく設計の節で引くのが正しい。
- 版の動き: 06 版が 2026-08-03。SSHM WG の Related Internet-Drafts に載っているが **WG 採択はされていない**。WG での議論状況は sshm ML を読めていないため unknown（ML の巡回が 3 回連続で失敗している）。
- セキュリティ上の限界を著者自身が認めている: 一方向認証なので active attacker がいると pass-the-hash が成立する。自分が nonce の先出しに使う場合、**この Comment 欄の値は改竄されうる**（鍵交換前なので MAC で保護されていない）ことを前提にする必要がある。すなわちここに載せた challenge は、後段で session identifier H と一緒に再確認しないと freshness の根拠にならない。これは `2026-sardar-identity-crisis-attested-tls.md` の指摘と同じ構造の落とし穴。
- Comment 欄をカンマ区切りで共有する設計は、複数の拡張が衝突なく同居するための登録機構が無い。自分が別の値を載せるなら名前空間をどう確保するかを考える必要がある。
