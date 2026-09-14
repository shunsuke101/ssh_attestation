---
id: arxiv:1801.05863
title: "Integrating Remote Attestation with Transport Layer Security"
authors: ["Thomas Knauth", "Michael Steiner", "Somnath Chakrabarti", "Li Lei", "Cedric Xing", "Mona Vij"]
year: 2018
venue: "preprint (arXiv). v1 2018-01-17 / v2 2019-07-26"
url: "https://arxiv.org/abs/1801.05863"
doi: 10.48550/arXiv.1801.05863
type: paper
tags: [ra-tls, attested-tls, sgx, x509-extension, secure-channel-integration, foundational]
relevance: high
added: 2026-09-14
---

## 概要

Intel SGX の remote attestation を TLS の接続確立に統合する RA-TLS の原典。**既存のプロトコル実装を変更せずに**統合することを目標に掲げ、attestation の結果を X.509 証明書の中に持ち込むことで TLS のハンドシェイクそのものには手を入れない、という方針を採る。OpenSSL・wolfSSL・mbedTLS の 3 つの OSS TLS ライブラリでプロトタイプを作り、TLS のエンドポイントを SGX enclave に束縛できることを示した。

## 手法・貢献

- **中心のアイデア**: enclave が自分で鍵ペアを生成し、その公開鍵を含む attestation の証拠を、自己署名 X.509 証明書の拡張フィールドに埋め込む。TLS 側から見れば「ただの証明書」なので、ハンドシェイクのメッセージ列は標準のまま。検証は証明書検証のコールバックで行う。
- これにより「TLS の鍵」と「attestation の対象 enclave」が同一であることが、証明書という既存の器だけで結び付く。
- 脅威モデル: SGX の標準的な前提（OS・ハイパーバイザは信頼しない、enclave の内部は保護される）。
- 前提とする信頼点: SGX の quoting enclave と Intel Attestation Service。
- 評価方法: 3 ライブラリでの実装可能性の提示が主で、詳細な性能評価やプロトコルの形式的な安全性証明は主眼ではない。

## 自研究との関係

（※ここは自分の解釈）

- [x] **前提** — 自分が土台として使う（引用して当然視できる）
- [ ] **競合**
- [x] **部品** — 一部を借用できる
- [x] **背景** — Introduction の文脈づけに使う

`docs/scope.md` の「中心的な問い」との対応:

- **問い 1（どのレイヤで Evidence を運ぶか）** — この論文が出した答えは「**証明書に入れる**」。SSH でいえば OpenSSH 証明書の extension フィールドに Evidence を載せる案の直接の先例にあたる。`notes/specs/draft-ietf-sshm-cert.md` の critical/non-critical extension の議論と繋げて読むべき。
- **問い 2（後方互換性）** — 「プロトコル実装を変えない」という制約を最初に立てた仕事。`2026-gu-sessionlatch-unmodified-tls-attestation.md` はこの制約をさらに押し進めて証明書すら変えない方向に行っている。**後方互換の強度には段階があり、この論文 → SessionLatch の順で厳しくなる**、という整理は自分の論文の Related Work の軸として使える。

**重要な留保**: この論文が提案した RA-TLS は、その後 `2026-sardar-identity-crisis-attested-tls.md` の形式検証で、その派生である Interoperable RA-TLS が **Evidence freshness・server identity・server authentication・compound authentication を満たさない**と指摘されている。したがってこの論文は「土台として引くが、そのまま真似してはいけない先行研究」という位置づけになる。引用するときは必ず Sardar らの指摘とセットで書くこと。

なぜ 2019 年より古いのに拾ったか: `docs/scope.md` の時間範囲は 2019 年以降を目安としつつ「土台となる文献は年に関係なく拾う」としている。secure channel protocol への attestation 統合という問題設定そのものの出発点であり、SEAT WG の文書群も実質ここから始まっているので、土台として扱う。

## 引用すべき箇所

> without modifying existing protocol implementations — abstract

（※ arXiv の abstract ページから取得。**本文の節・ページ番号は未確認。** 詳細な引用は PDF 本文を当たってから補うこと）

## 未解決・気になる点

- v2（2019-07-26）で何が変わったかを確認していない。引用するなら版を明示すること。
- arXiv 上に会議・ジャーナルの掲載情報が出ていない。preprint のままの可能性が高いが、`unknown` として扱い、後で採録先が判明したら追記する。
- 証明書に Evidence を入れる方式は、**証明書のサイズ**と**失効・鮮度**の問題を持ち込む。SSH 証明書でも同じ問題が出るはずで、問い 4 と問い 5 に直結する。SSH のパケット長の制約（RFC 4253 の 35000 バイト）との兼ね合いを自分で計算しておく。
- 自己署名証明書を使う前提なので、既存の企業 PKI とは共存しない。SessionLatch が「企業証明書をそのまま残す」ことを売りにしているのは、この点への反論になっている。
