---
id: "url:https://github.com/openconfig/attestz"
title: "openconfig/attestz — TPM enrollment and attestation workflow (EnrollZ / AttestZ) for network devices"
project: "OpenConfig attestz"
version: "main（GitHub にリリースとタグなし。Bazel registry の openconfig_attestz は 0.6.10）"
language: "Protocol Buffers / gRPC"
license: "Apache-2.0"
url: "https://github.com/openconfig/attestz"
type: impl
tags: [openconfig, gnoi, gnsi, grpc, attestz, enrollz, tpm2, iak, idevid, oiak, pcr-quote, nonce, reference-values, eat, network-device, arista, parallel-theme]
relevance: high
added: 2026-10-26
---

> 一次情報: README（`https://github.com/openconfig/attestz`）と `proto/tpm_attestz.proto`（2026-10-26 に WebFetch で確認）。採用例として Arista の TOI "Support for Enrollment and Attestation (enrollz/attestz)"（2026-04-21、EOS 4.36.0F のタグ付き）。

## 何が実装されているか

ネットワーク機器の TPM 2.0 について、機器の所有者（switch owner）が使う enrollment と attestation の手順、API、参照実装をまとめた OpenConfig のプロジェクト。2 つの gRPC サービスからなる。

- **EnrollZ**: 機器の TPM に根ざした identity（ベンダーが工場で入れた IAK と IDevID）を検証し、所有者の証明書（oIAK と oIDevID）に差し替える。
- **AttestZ**: nonce 付きの PCR Quote を取り、機器の boot 状態が所有者の期待どおりかを確かめる。

機器側のエンドポイントは gNOI / gNSI / gNMI と同じポート 9339 で提供する。前段の Bootz は README によれば "an evolution of sZTP"。

## 今回の変更点

リリース単位ではなくリポジトリ全体を読んだ。`Attest` RPC の定義（`TpmAttestzService`）:

| 方向 | フィールド | 内容 |
|---|---|---|
| 要求 | `control_card_selection` | 対象の control card |
| 要求 | `nonce`（bytes） | PCR Quote 用の乱数。長さの規定は proto にない |
| 要求 | `hash_algo` | PCR bank のハッシュアルゴリズム |
| 要求 | `pcr_indices`（repeated） | Quote に含める PCR |
| 応答 | `quoted` | `TPM2_Quote` の `TPM2B_ATTEST`（生のバイト列） |
| 応答 | `quote_signature` | IAK による署名 `TPMT_SIGNATURE` |
| 応答 | `pcr_values`（map） | 署名されない最終 PCR 値 |
| 応答 | `attestation_cert` | TPM 2.0 なら oIAK 証明書（旧 `oiak_cert` は deprecated） |
| 応答 | `oidevid_cert` | standby の card のみ |
| 応答 | `eventlog_bytes`（optional） | TCG Canonical Event Log 形式の event log |
| 応答 | `format` / `eat_token` | TPM_RAW のほか EAT_JWT / EAT_CWT（RFC 9711）も選べる |

EnrollZ 側には `GetIakCert`、`RotateOIakCert`、`GetControlCardVendorID`、`Challenge`（EK で包んだ HMAC 鍵による所持証明）、`GetIdevidCsr` などの RPC がある。

## 技術的な構成

- 信頼点: TPM 2.0。鍵と証明書の構成は TCG "TPM 2.0 Keys for Device Identity and Attestation" に従う（README）。ECC P-384 と SHA-384 の要件は TCG の PC Client Platform TPM Profile を参照
- 依存: gRPC（gNOI / gNSI と同居）。README は IETF の CHARRA と TCG の RIM を将来の検討事項として挙げる
- SSH との接続点: なし。gRPC で TLS の上

## 自研究との関係

（※自分の解釈）

**並行テーマに効く。** 主テーマには、Verifier の判定条件の参考として効く。

- 借用できる部分: `Attest` の応答は `quoted`、`quote_signature`、`pcr_values` の 3 つで、RFC 9684 の `quote-data`、`quote-signature`、`unsigned-pcr-values` と、並行テーマの `rats-attester.so` が返すものと同じ形をしている。NETCONF / YANG（RFC 9684）と gRPC（attestz）の 2 系統が、同じ Evidence の形に収束していると言える。
- 判定の考え方: README は、boot log からの再計算を意図的に避け、最終 PCR 値を事前に計算した参照値と比べると書いている。Nokia SR Linux が最終 PCR 値だけの参照値ファイルを配るのと同じ方針（[[nokia-srlinux-tpm-remote-attestation]]）。並行テーマの Verifier が「PCR digest と Reference Value の照合」で済ませる設計の裏付けになる。
- 自分の提案と重なる部分: 所有者が工場の IAK を自分の oIAK に差し替える enrollment は、主テーマで SSH サーバーが AK をどう信頼するか（問い 3）の参考になる。
- この実装が**やっていない**こと: Quote をどのセッションに束縛するかは proto に書かれていない。nonce の長さや有効期限の規定もない。

## 動かすなら

未検証。参照実装のビルドと、enrollz / attestz を実装した機器（Arista EOS など）が要る。

## 未解決・気になる点

- Arista 以外（Cisco、Juniper、Nokia）が attestz を実装しているかは、公開情報で確認できなかった
- README の "Attesting secrets is an antipattern." の意図（秘密情報を測定対象にしない、という意味か）
- Arista の TOI 本文（対応機種と制約）は "Read More" の先で未読
