---
id: "url:https://netconfcentral.org/modules/Cisco-IOS-XR-remote-attestation-act/2020-09-26"
title: "Cisco-IOS-XR-remote-attestation-act (YANG module, revision 2020-09-26)"
project: "Cisco IOS XR"
version: "2020-09-26"
language: "YANG"
license: "Simplified BSD License（モジュール本文の IETF Trust 表記による）"
url: "https://www.netconfcentral.org/modules/Cisco-IOS-XR-remote-attestation-act/2020-09-26"
type: impl
tags: [netconf, yang, cisco, ios-xr, remote-attestation, tpm, pcr-quote, nonce, tcg-event-log, ima, vendor-module, parallel-theme]
relevance: high
added: 2026-10-26
---

> 一次情報: netconfcentral の source（`/source/cooked/`）と、YangModels リポジトリの `vendor/cisco/xr/731/Cisco-IOS-XR-remote-attestation-act.yang`（2026-10-26 に WebFetch で確認）。

## 何が実装されているか

Cisco IOS XR が NETCONF で公開している独自の YANG モジュール。description は "This module defines procedure for remote attestation of a network platform's security posture." で、ネットワーク機器のハードウェアとソフトウェアの trustworthiness を評価するためのものと書かれている。netconfcentral に載っている 2020-09-26 版は RPC 6 本と notification 3 本からなる。

| RPC | 入力 | 出力 |
|---|---|---|
| `get-certificate` | `nonce`（binary 0..64）、`certificate-identifier`、`location` | 証明書チェーン（DER）、`nonce`、`signature_version`、`signature` |
| `attest-platform-config-registers` | `pcr-index`（leaf-list、1 個以上）、`nonce`、`attestation-certificate-identifier`、`location` | `nonce`、TPM ごと（`tpm-name`）の PCR 値リスト、`up-time`、`pcr-quote`、`pcr-quote-signature` |
| `get-platform-boot-integrity-event-logs` | `location`、`start-event-number`、`end-event-number` | TCG event log（`event-number`、`event-type`、`pcr-index`、`digest-list`、`event-data`） |
| `get-platform-ima-event-logs` | 同上 | IMA event log（`ima-template`、`filename-hint`、`filedata-hash`、`template-hash`、`pcr-index`、`signature`） |
| `get-platform-ima-audit-event-logs` | `location` | IMA appraisal の監査ログ（`filename`、`cause` は invalid-signature / invalid-hash / missing-hash） |
| `get-platform-hardware-integrity-measurements` | `nonce`、`digest-hash-algorithm`、`location` | `known-good-digest` と `observed-digest`、PCR、`pcr-quote`、`pcr-quote-signature-format`（TPM2 / CISCO）、`pcr-quote-signature` |

notification は `hardware-intergrity-failure`（原文の綴りのまま）、`boot-integrity-failure`、`runtime-integrity-failure` の 3 つ。

## 今回の変更点

YangModels の 731 版の revision 文による改訂履歴:

| revision | 内容 |
|---|---|
| 2017-06-08 | Initial revision. |
| 2018-10-08 | Adding Hardware integrity RPC |
| 2019-04-05 | Establish semantic version baseline. |
| 2019-10-01 | Made changes to be RFC6087 compliant |
| 2020-07-10 | Added xr-task so that Limited access user should not configure router using this model |

731 版は RPC が 5 本で、IMA 監査ログの RPC がない。netconfcentral の 2020-09-26 版は 6 本。2020-09-26 版を載せている IOS XR のリリースは未確認。

## 技術的な構成

- 信頼点: TPM。`pcr-quote-signature` は TPM の restricted key（ECC / RSA）による署名。署名形式は TPM2 と CISCO の 2 種類
- 依存: unknown（ルーター OS の内部）
- SSH との接続点: NETCONF（RFC 6242 により SSH の上）。Verifier は NETCONF クライアントとして接続するので SSH クライアント側になる

## 自研究との関係

（※自分の解釈）

**並行テーマに効く。** 主テーマには、役割の向きが逆の対比としてだけ効く。

- 借用できる部分: `attest-platform-config-registers` は、RFC 9684 の `tpm20-challenge-response-attestation` と同じ形をしている。nonce と PCR の選択を送り、PCR 値、quote、署名を受け取る。event log を別の RPC で取る分け方も RFC 9684 と同じ発想。並行テーマの `rats-attester.so` が返す `unsigned-pcr-values` に当たるのが PCR 値のリスト。
- 自分の提案と重なる部分: RFC 9684（2024-12）より前の 2017 年から、製品で NETCONF 越しの TPM attestation が提供されていた実例になる。Related Work では「標準化以前のベンダー実装」として位置づけられる。
- この実装が**やっていない**こと:
  - Verifier の判定（照合の手順）はモジュールの範囲外。
  - event log を取る RPC に nonce がない。log 取得そのものには freshness がない。
  - `get-platform-hardware-integrity-measurements` は `known-good-digest` を Attester 側が返す。Reference Value を Attester が持つ形で、RATS の役割分担（Reference Value Provider と Verifier）から外れる。
- 推測（未確認）: description に "This version of this YANG module is part of RFC VVVV." と IETF Trust のライセンス文が残っている。標準化を前提に書かれた可能性がある。Cisco の Eric Voit は RFC 9683 / 9684 の共著者でもあるが、このモジュールと RFC 9684 の系譜上の関係は確認していない。

## 動かすなら

未検証。IOS XR の実機か XRd が要る。

## 未解決・気になる点

- 2020-09-26 版を含む IOS XR のリリース
- `pcr-quote` の中身が `TPMS_ATTEST` そのものか。CISCO 形式の署名とは何か
- RFC 9684 の策定過程で、このモジュールがどう扱われたか（`draft-ietf-rats-yang-tpm-charra` の謝辞や議論）
- Juniper、Huawei、Nokia に同種のモジュールがあるかは未調査
