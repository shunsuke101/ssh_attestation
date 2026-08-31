---
id: "url:https://datatracker.ietf.org/group/seat/about"
title: "Secure Evidence and Attestation Transport (SEAT)"
body: "IETF"
status: "Active Working Group"
year: unknown
url: "https://datatracker.ietf.org/group/seat/about/"
type: spec
tags: [seat, tls, dtls, remote-attestation, rats, ietf, channel-binding]
relevance: high
added: 2026-08-21
---

## 何を規定しているか

IETF の **SEAT（Secure Evidence and Attestation Transport）Working Group** は、remote attestation を認証済み (D)TLS 接続に束縛するための Standards Track プロトコルを作ることを憲章としている。ユースケース文書と、attested (D)TLS 拡張の仕様の 2 つをマイルストーンに掲げる。

憲章の言葉では「the Secure Evidence and Attestation Transport (SEAT) WG will document a set of use cases that protocols such as (D)TLS should be able to support」。対象は **(D)TLS 1.3 のみ**に限定され、TLS のコアプロトコル自体は変更しない方針。RATS WG の成果物を土台に使う。

**注意**: 憲章ページには WG の設立年月が明示されていない（本ノート作成時点で `year: unknown`）。正確な設立時期が必要になったら charter の履歴を当たること。

## 本研究に効く定義・要件

| 憲章の要素 | 内容 | どう使うか |
|---|---|---|
| 適用範囲 | (D)TLS 1.3 に限定 | **SSH は明示的に対象外。ここが本研究の空白地** |
| 認証の方向 | server authentication が主、client authentication は optional | SSH でも「ホスト → クライアント」が主、逆が従、という構成の裏付けになる |
| コア変更の禁止 | TLS プロトコル自体は変えない | SSH でも「トランスポート層を書き換えない」制約を課す根拠として引ける |
| freshness | Evidence と Attestation Result の **per-connection freshness** を保証する | 中心的な問い 4 に直結。SEAT がどう解いたかをそのまま参照できる |
| 証明対象 | software, firmware, secure boot status, cryptographic key storage の trustworthiness | Evidence に何を含めるかの既成の合意事項 |
| 基盤 | RATS WG の既存文書を活用 | RFC 9334 / EAT / CMW を再利用する前提 |

## 拡張点・自由度

SEAT は (D)TLS に閉じているため、**同じ問題を SSH で解く仕事は誰もやっていない**。ここが本研究の位置づけの中心になる。

SSH と TLS の差で、SEAT の設計をそのまま移植できない点:

- SSH には TLS の Exported Authenticators（RFC 9261）に相当する post-handshake authentication の枠組みが無い
- SSH は X.509 証明書ではなく独自のホスト鍵／証明書形式を使う
- SSH のユーザ認証はトランスポート層確立後の別フェーズ（`ssh-userauth`）で走る

## 他仕様との関係

- **土台**: RFC 9334 (RATS Architecture) → [[rfc9334-rats-architecture]]
- **具体案**: draft-fossati-seat-expat → [[draft-fossati-seat-expat]]
- **前身**: draft-fossati-tls-attestation（withdrawn）、draft-fossati-tls-exported-attestation（expired、seat-expat に置換）
- Evidence 形式として EAT (RFC 9711)、包装として CMW (RFC 9999) を参照

## 引用すべき箇所

> the Secure Evidence and Attestation Transport (SEAT) WG will document a set of use cases that protocols such as (D)TLS should be able to support
> — SEAT WG charter

## 自研究との関係

（※ここは解釈）

**この WG の存在が、本研究の Introduction の論拠そのものになる。** 「セキュアチャネルプロトコルに attestation を束縛する」という課題は、IETF が WG を立ててまで取り組む程度には重要だと産業界・標準化界が認めている。にもかかわらず **SSH は対象外**。

したがって主張の骨格は次のように立てられる:

1. attestation をセキュアチャネルに束縛する必要性は IETF SEAT WG が認めている（＝問題設定の正当性は借りられる）
2. しかし SEAT は (D)TLS 1.3 に限定されている
3. SSH は TLS と異なる認証モデル（TOFU、独自証明書、多段のユーザ認証）を持つため、SEAT の解をそのまま移植できない
4. よって SSH 固有の設計が要る ← 本研究の貢献

**最優先の次アクション**: SEAT WG のメーリングリスト（`seat@ietf.org`）を巡回先に加え、SSH への適用が議論されたことがあるか確認する。もし議論されて棄却されているなら、その理由は本研究の設計制約になる。逆に誰も言及していないなら、それ自体が空白の証拠になる。

## 未解決・気になる点

- WG の設立時期と、現在の具体的な採用文書（adopted drafts）は何か
- SSH への適用が ML で議論されたことはあるか
- 「TLS のコアを変えない」制約を SSH に移すと、どのフェーズに attestation を挿せるのか（KEX 後・userauth 前？ 新規 global request？）
- per-connection freshness を SEAT はどう実現しているか（nonce か epoch marker か）
