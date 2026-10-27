---
id: "url:https://cisco.com/c/en/us/products/collateral/cloud-systems-management/crosswork-network-automation/datasheet-c78-741972.html"
title: "Cisco Crosswork Cloud Trust Insights Data Sheet"
vendor: "Cisco"
product: "Crosswork Cloud Trust Insights / IOS XR trust dossier"
date: 2024-06-04
url: "https://www.cisco.com/c/en/us/products/collateral/cloud-systems-management/crosswork-network-automation/datasheet-c78-741972.html"
type: industry
tags: [cisco, ios-xr, trust-insights, trust-dossier, known-good-values, kgv, tam, sudi, nonce, verifier, background-check, ssh, cli-signing, parallel-theme]
relevance: high
added: 2026-10-26
---

> 一次情報は 3 つ。データシート（最終更新 2024-06-04、GA は 2021-11-03）、Crosswork Cloud のユーザーガイドの "About Trust Insights"（2020-01-23 付）、Cisco Live EMEA 2024 の BRKSPG-2868 "Building & Maintaining Trust in Service Provider Networks"（Rakesh Kandula、PDF を手元で `pdftotext -raw` にかけて読んだ）。

## 何が発表されたか

Cisco が IOS XR ルーター向けに、機器の完全性を外部で検証するクラウドサービス Crosswork Cloud Trust Insights を提供している。IOS XR 7 の機器が署名付きの「trust dossier」を作り、オンプレミスの Crosswork Data Gateway がそれを集めてクラウドに送る。クラウド側は、Cisco が署名して公開する Known Good Values（KGV）と照らし合わせる。

## 技術的な中身

- **信頼点**: 機器のハードウェアに組み込んだ Trust Anchor module（TAm）。BRKSPG-2868 によれば、TAm は SUDI や AIK の証明書を保管し、secure boot の起点にもなる。SUDI は製造時に TAm に入れる IEEE 802.1AR の機器 identity で、Cisco が署名し、PID とシリアル番号を含む。
- **Evidence（trust dossier）の中身**（BRKSPG-2868 の "Example of IOS-XR Trust Dossier" のスライド）:
  - OS の版とプラットフォーム
  - **anti-replay nonce**（CLI のオプションで指定）
  - ハードウェアの inventory（`Cisco-IOS-XR-invmgr-oper.yang` など）
  - ハードウェアの attestation データ（`Cisco-IOS-XR-remote-attestation-act.yang`、[[cisco-ios-xr-remote-attestation-act-yang]]）
  - SUDI 証明書と、FRU ごとの別々の署名（nonce を含む）
  - ソフトウェアパッケージの inventory、再起動の履歴、設定のロールバック履歴
  - 出力は CLI による人間が読める JSON で、「Signed envelope (not encrypted)」
- **検証の主体（Verifier に相当するもの）**: Crosswork Cloud Trust Insights。dossier の証拠を検証して稼働中のハードウェアとソフトウェアの時系列に加え、Cisco の KGV と照合する。KGV.json は Cisco が署名し、boot integrity、boot0 image、boot OS image、running image の各ファイルの測定値を含む（ユーザーガイド）。KGV の出どころは、Cisco のプレゼン資料では IOS XR のビルドと回帰試験、Cisco コミュニティの FAQ では Cisco の製造工程とされる（いずれも検索結果による。本文は未読）。
- **収集の経路**: ユーザーガイドは、Data Gateway が「logs in to the devices and gathers the trust dossier」と書く。機器側のプロトコル（SSH 越しの CLI、NETCONF、gRPC）は明記されていない。
- **対応する RATS モデル**: Background-Check（機器が Evidence を出し、外部の Verifier が判定する）。ただし Cisco はこの用語を使っていない。
- **公開仕様の有無**: dossier の形式の公開仕様は見当たらない。ハードウェア attestation の部分は YANG モジュールとして公開されている。

### SUDI による CLI 出力の署名（BRKSPG-2868 の "SUDI Based CLI Signature Utility" のスライド）

IOS XR は、任意の CLI 出力に SUDI の秘密鍵で署名する機能を持つ。目的は「to ensure the output is from a genuine device and not a replay from meddler-in-the-middle (MITM) attack」。例:

```
RP/0/RP0/CPU0:Galapagos#show version | utility sign nonce ABCD
```

出力は JSON で、`cli-output` と、`nonce`、`signature-version`、`sudi-signature` を含む `signature-envelop` からなる。別のスライドは、管理サーバーが一意の nonce で SUDI を challenge し、ルーターが nonce を含めて SUDI 鍵で署名した証明書チェーンを返す、偽造品検出の流れを示す。IOS XE でも Catalyst 2960X/XR の Field Notice FN72399 が `show platform sudi certificate sign nonce` を案内し、「Do not use a static value for all validations on a particular device.」と注意している。

## 自研究との関係

（※自分の解釈）

**並行テーマに効き、主テーマにも対比として効く。**

- **商用で既に解かれている問題**: ルーターの boot と実行時の完全性を、ベンダーが署名した参照値（KGV）で外部から検証する仕組みは、製品として 2021 年から提供されている。並行テーマの Verifier（署名、nonce、PCR digest、Reference Value の照合）は、この製品の機能の一部に当たる。
- **主テーマとの関係**: SUDI による CLI 出力の署名は、SSH の管理セッションの中で、応答が本物の機器から来た新しいものだと nonce で示す仕組みになっている。ただし、署名は SSH のセッションに束縛されていない。nonce は利用者が CLI で手入力し、スライドの例は固定値の `ABCD` である。向きもルーターが Attester、管理者の SSH クライアントが Verifier で、主テーマ（Attester = SSH クライアント）とは逆。BRKSPG-2868 が挙げる SSH の強化策は公開鍵認証、証明書認証、MFA で、SSH のユーザ認証に attestation を組み込む記述はない。
- **商用が解いていない問題（＝研究の余地）**: (1) Evidence を SSH のセッションに束縛すること。(2) 接続元の端末を Attester にすること。(3) dossier の形式とプロトコルの標準化（Cisco 独自の形式で、RFC 9684 との関係は不明）。
- **論文で「実務での需要」の根拠として引用できるか**: 引用できる。主要なルーターベンダーが、完全性検証の製品と、MITM の再送を防ぐための nonce 付き署名をすでに出荷している。

## 未解決・気になる点

- dossier の署名鍵が SUDI か AIK か（スライドは FRU ごとの SUDI 署名を挙げるが、PCR Quote の署名鍵は書いていない）
- Data Gateway が機器に「log in」する経路が SSH の CLI か
- Trust Insights の対応機種の一覧（データシートは「IOS XR 7 systems」とだけ書く）
- KGV.json の形式（CoRIM や TCG RIM との関係）
