---
id: "url:https://documentation.nokia.com/srlinux/26-7/books/pdf/Software_Installation_Guide_26.7.pdf"
title: "SR Linux Software Installation Guide Release 26.7 — TPM Keys (IDevID and IAK), Measured Boot, Remote Attestation / Integrity Verification"
project: "Nokia SR Linux"
version: "26.7"
language: "unknown（ネットワーク OS の機能）"
license: "unknown（商用製品）"
url: "https://documentation.nokia.com/srlinux/26-7/books/pdf/Software_Installation_Guide_26.7.pdf"
type: impl
tags: [nokia, sr-linux, tpm2, idevid, iak, measured-boot, pcr-quote, nonce, challenge-response, reference-values, ima, tcg-event-log, network-device, parallel-theme]
relevance: high
added: 2026-10-26
---

> 一次情報: 同ガイドの §3.5 と §3.6（PDF を手元で `pdftotext` にかけて読んだ。2026-07 作成の版）。

## 何が実装されているか

Nokia のネットワーク OS である SR Linux が、control card（CPM）の TPM 2.0 を使った measured boot と remote attestation を提供している。ガイドは「SR Linux follows the challenge-response interaction model.」と明記し、Verifier が nonce と PCR の選択を指定して Quote を取る手順を示す。

- **鍵**: 工場で IDevID と IAK を TPM に入れ、Nokia IP Routing Factory CA が証明書に署名する。TCG "TPM 2.0 Keys for Device Identity and Attestation" に従う。証明書の subject に control card のシリアル番号を入れ、TPM と card を結びつける。IAK は TPM の restricted signing key で、Quote の署名に使う。
- **IDevID の用途**: secure remote bootstrap でクライアントとして、TLS server profile でサーバーとして、機器を認証する。冗長構成では active の card が standby の card の IDevID を検証してから同期を許す。
- **測定**: boot から kernel までの事象は BIOS log に、実行時は Linux IMA が PCR 10 に記録する。

| PCR | 内容（ガイドの表 4） |
|---|---|
| 0 | BIOS |
| 2 | UEFI driver / application code |
| 4 | Boot manager code（SHIM、GRUB、kernel） |
| 6 | Host platform manufacturer specific |
| 9 | GRUB が読み込み・実行したファイル（kernel、initramfs） |
| 14 | Root file system（SquashFS） |

## 今回の変更点

26.7 版のガイドを読んだ。24.7 版の目次には PCR 割当の表示しかなく、PCR 値、event log、参照値、remote attestation の節は 25.7 版以降の目次に現れる（Web 検索の結果による。24.7 と 25.7 の本文は未読）。

## 技術的な構成

- 信頼点: control card の TPM 2.0（RSA-2048 または ECC P-384。機種による）
- 依存: unknown
- SSH との接続点: なし。ガイドの手順は CLI の `tools platform trust attestation` コマンドで、外部の Verifier がどの経路で呼ぶか（gNMI、JSON-RPC、SSH 越しの CLI など）は書かれていない

CLI の例:

```
# tools platform trust attestation control A pcr-quote pcr-selection sha256:0,1,4,9 nonce AQIDBAU=
# tools platform trust attestation control A pcr-read pcr-selection "sha256:0,1,2,3,4,5,6,7,8,9,10"
# tools platform trust attestation control B log-retrieval bios display from 1 to 2
# tools platform trust attestation control B log-retrieval ima display from 1 to 1
# show platform trust tpm control B certificate initial-attestation-key
```

`pcr-quote` は "Quote Message"、"Quote Message Signature"、"Quoted PCRs" を base64 で返す。nonce は「base64 operator generated number」で、`pcr-selection` は tpm2-tools 互換の文字列。

**参照値**: リリースごとに `known_good_pcr_values.json` を配布物に同梱し、`/mnt/nokiaos/<build binary.bin>/` に置く。ガイドの注記は「Reference values only include the final PCR value, not the individual PCR events value.」。IMA については「Linux IMA does not have a known good final PCR value」と書き、IMA の PCR は参照値の対象外としている。

## 自研究との関係

（※自分の解釈）

**並行テーマに効く。** 主テーマには、参照値の配り方の実例として効く。

- 借用できる部分: nonce と PCR の選択を入力し、Quote、署名、PCR 値を返す形は、RFC 9684 の `tpm20-challenge-response-attestation` と OpenConfig の attestz（[[openconfig-attestz-enrollz]]）と同じ。並行テーマの Verifier が照合する「署名、nonce、PCR digest、Reference Value」の 4 点が、そのまま製品の手順になっている。
- 参照値の設計: ベンダーが最終 PCR 値だけをリリースに同梱する方式は、event log を再計算しない attestz の方針と一致する。並行テーマで Reference Value を「最終 PCR 値の集合」として持つ設計の裏付けになる。一方で IMA の PCR は参照値で判定できないと明記しており、実行時の完全性は別の判定が要る。
- この実装が**やっていない**こと: 判定そのもの（Verifier）は機器の外に置く前提で、Nokia の Verifier 製品はガイドに出てこない。Nokia Bell Labs には実験的な Verifier の A10（`nokia-steward/AttestationEngine`、2026-10 時点で archived）があるが、SR Linux との関係は確認していない。

## 動かすなら

未検証。対応機種（7220 IXR-H5、7250 IXR-X4、7730 SXR など）の実機が要る。SR Linux のコンテナ版で TPM の機能が使えるかは未確認。

## 未解決・気になる点

- 外部の Verifier が Quote を取る経路（gNMI、JSON-RPC、gNOI attestz のどれか）
- `known_good_pcr_values.json` の形式と署名の有無
- SR OS（同社のルーター OS）に同じ機能があるか。SR OS 23.7.1 の secure boot の文書には TPM と attestation の記述がなかった
