---
id: "url:https://github.com/smallstep/ssh-attest-proxy"
title: "SSH SK Attestation Proxy — embed FIDO security key attestation into SSH certificates and verify it at the server"
project: "ssh-attest-proxy (smallstep)"
version: "unknown（リリース・タグなし。最終 push 2025-11-20）"
language: "Go"
license: "unknown（LICENSE ファイルなし）"
url: "https://github.com/smallstep/ssh-attest-proxy"
type: impl
tags: [ssh-certificate, fido2, security-key, attestation, authorized-principals-command, smallstep]
relevance: high
added: 2026-08-31
---

## 何が実装されているか

OpenSSH の `-sk` 鍵（FIDO セキュリティキー常駐鍵）について、「その鍵が本当にハードウェア内に存在するか」をサーバ側が検証できないという非対称性を埋める PoC。`ssh-keygen` が出力する attestation 情報を **SSH ユーザ証明書の独自 extension として証明書の中に埋め込み**、接続時にサーバがそれを取り出して FIDO ルート CA まで鎖を検証する。README に `**This is an educational project and is not suitable for production use.**` と明記されている。

## 今回の変更点

初回収集のため差分ではなくプロジェクト全体を対象にした。リリース・タグは切られておらず、2025-04-16 作成 / 2025-11-20 最終 push、star 10。

## 技術的な構成

- 信頼点: FIDO2 セキュリティキー（YubiKey で確認）。TPM ではない。鍵種は `ed25519-sk` と `ecdsa-sk`
- 依存: Go。証明書生成側 `ssh_ca_attest`、検証側 `verify_ssh_ca_attestation` の 2 コマンド構成（`cmd/` 以下）
- SSH との接続点: **SSH 証明書の extension** `ssh-sk-attest-v01@step.sm` に Evidence を格納し、sshd 側は `AuthorizedPrincipalsCommand /bin/verify_ssh_ca_attestation --ca /etc/ssh/yubico-fido-ca.pem %u %t %k` として呼び出す。プロトコル本体には手を入れず、既存の拡張点だけで完結させている
- 検証: `--ca` で与えたルート CA（通常はハードウェアベンダの FIDO root CA）まで attestation 証明書チェーンを検証する。attestation を持たない証明書は無条件で拒否、検証後に principals が空になった場合も拒否

## 自研究との関係

（※ここからは自分の解釈）

- 借用できる部分:
  - **「中心的な問い 1（Evidence をどのレイヤで運ぶか）」に対する既存解の 1 つ**として、証明書の extension フィールドに載せる方式の実物。プロトコル改変ゼロで済むという後方互換性上の利点（問い 2）を実証している。
  - `AuthorizedPrincipalsCommand` を検証フックに使う手口は、sshd 本体を書き換えずに Verifier ロジックを差し込む方法として素直で、自分の PoC でも初期段階の足場に使える。
  - README 自身が「検証は個々のサーバではなく SSH CA 側で行うべき」と述べており、これは**問い 3（Verifier をどこに置くか）**の論点そのもの。Related Work で「実装者側の直感は CA 集約寄り」という証左として引ける。
- 自分の提案と重なる部分: Evidence を証明書に載せて既存 SSH 上を流す、という運搬経路の選択。
- この実装が**やっていない**こと（＝自分の貢献余地）:
  - 方向が**クライアント→サーバのみ**。本研究の主眼である「接続先ホストが正しい状態か」（サーバ→クライアント、ホスト鍵側の attestation）は扱っていない。
  - 証明する対象が**鍵の常駐性（key residency）だけ**で、プラットフォームの状態（measured boot / PCR / IMA）は含まない。TPM quote 的な状態証明ではない。
  - **Freshness がない**（問い 4）。attestation は証明書発行時点の一度きりで、証明書の有効期間中は使い回される。セッションへの束縛も nonce の運搬もない。接続時点でハードウェアが健全である保証にはならない。
  - Reference Value / appraisal policy の管理（問い 5）は `--ca` にルート CA を 1 つ渡すだけで、RATS 的な Verifier の枠組みにはなっていない。

## 動かすなら

**未検証**（README を読んだのみ）。試すなら YubiKey が要る。手順の骨子は、`ssh-keygen -t ed25519-sk -O write-attestation=...` で attestation を出す → `ssh_ca_attest` に公開鍵と attestation を渡して証明書を発行 → sshd 側に `AuthorizedPrincipalsCommand` を設定して接続、となる。正確なフラグは README を再確認すること。

## 未解決・気になる点

- extension 名 `ssh-sk-attest-v01@step.sm` はベンダ private 名前空間（`@step.sm`）。IANA 登録は当然なく、標準化の意図があるのかは不明。`notes/specs/iana-ssh-registry-and-extension-points.md` の登録要件（RFC 9519）と突き合わせて、自分の拡張をどの名前空間に置くか判断する材料になる。
- 証明書に載せる Evidence のサイズが SSH 証明書の実運用サイズにどう効くか（`test_data` に例があるはず）。TPM quote や CoRIM を載せる場合はさらに膨らむので、証明書方式のスケール限界を測る出発点になる。
- smallstep（商用 SSH CA ベンダ）が educational と断りつつ公開している点。製品側（`step-ca`）に取り込まれた形跡があるかは未確認。
- attestation を持たない証明書を一律拒否する設計は段階的導入と相性が悪い。混在期の扱いは自分の設計で詰める必要がある。
