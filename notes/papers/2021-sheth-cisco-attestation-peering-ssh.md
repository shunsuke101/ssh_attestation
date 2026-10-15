---
id: "url:https://patents.google.com/patent/US11165861B2/en"
title: "Attestation-based scheme for validating peering setups for critical infrastructure protocols"
authors: ["Sujal Sheth", "Shwetha Subray Bhandari", "Eric Voit", "William F. Sulzen", "Frank Brockners"]
year: 2021
venue: "US Patent 11,165,861 B2 (Cisco Technology, Inc.)"
url: "https://patents.google.com/patent/US11165861B2/en"
doi: null
type: paper
tags: [patent, cisco, ssh, attestation, tpm, nonce, challenge-response, prior-art, dhcp, dns, netconf, eric-voit]
relevance: high
added: 2026-10-13
---

> **本研究の先行技術として最重要の文献。** `docs/sources.md` で 2 回連続（2026-09-07, 2026-09-14）一次確認に失敗していたものを 2026-10-13 に確認できた。
> **型は `paper` にしているが特許である。** `CLAUDE.md` の `id` 規約に特許の形式がないため、フォールバックの `url:` を使った。

## 概要

重要インフラ系プロトコル（DHCP, DNS, SSH, ARP, NDP, SCP/SFTP, netconf）の **peering 確立時に、相手ノードが侵害されていないことを attestation で検証する**方式の米国特許。Cisco Technology, Inc. 名義。

- 出願: 2020-02-06 / 登録: 2021-11-02 / 優先日: 2019-04-05
- 発明者に **Eric Voit** を含む。Voit は RFC 9683（[[rfc9683-riv-tpm-network-devices]]）と [[draft-ietf-rats-reference-interaction-models]] の共著者でもある
- 公開番号 US20200322423A1。継続出願として **US 11570242 B2 / US 11652874 B2 / US 11882176 B2 / US 12363191 B2** が存在する

## 手法・貢献

- 脅威モデル: peering しようとする相手ノード／デバイスが侵害されている（"has been compromised"）場合に、それを検知せずに接続してしまうこと
- 前提とする信頼点: TPM。測定値とログを trusted storage に保持する
- Evidence の中身として明細書が列挙するもの: secure boot の情報、ソフトウェア変更のログ、各プロセスのソフトウェア版チェックサム、trusted storage をサポートすることの証明、CPU / NPU / センサ等**ハードウェア構成要素の完全性**
- freshness: 要求側が乱数生成器で **nonce** を作って要求に含め、相手は TPM でそれを含めて署名する。明細書は nonce の目的を再生攻撃防止と暗号ハッシュへの入力と説明する
- 評価方法: 特許なので評価はない

### SSH 実施例（明細書の記述そのまま）

> SSH with attestation can be implemented as follows. Before connecting to a peer node/device, a verification process can be performed to verify that the peer node/device has not been compromised. This can be performed by leveraging SSH for the peer node/device. **The SSH server can send, in addition to server credentials (e.g., public cryptographic key or digital certificate), the additional information to the SSH client to convey its own node/device integrity related data.** [...] The SSH client can review this attestation information and determine whether to continue or reject the SSH session establishment. Some of the above information can be continuously provided by the SSH server while the session is active. The information can be provided periodically, on demand (e.g., the SSH client requests such information again or SSH rekey interval) or in response to a triggering event (e.g., PCR change on SSH server). The session may be terminated immediately in response to either the SSH server having failed to provide attestation information or as a result of the attestation information indicating a lack of trustworthiness.

**この実施例は SSH サーバー → クライアント方向である。** サーバーが自分の完全性データをクライアントに送り、クライアントが接続を続けるか拒否するかを決める。**クライアントがサーバーに Evidence を送る記述は明細書にない**（取得できた範囲では）。

また、**rekey 間隔での再提示**（"SSH rekey interval"）と **PCR 変化を契機とした再提示**が明示されている。

## 自研究との関係

（※ここは解釈）

- [ ] **前提**
- [x] **競合** — 同じ「SSH に attestation を入れる」問題を扱っている。差分を明示する必要がある
- [ ] **部品**
- [x] **背景** — Introduction / Related Work で必ず触れる

`docs/scope.md` の「中心的な問い」との対応: **問い 1（どのレイヤで運ぶか）・問い 4（freshness）・問い 5（継続的な再検証）**に、2019 年時点の答えが既にある。

### 方向の違いが決定的

本研究は 2026-09-07 に attestation の方向を**クライアント → サーバー**に定め、2026-10-13 にテーマを「attestation をクライアント認証に拡張する」に明確化した。**この特許の SSH 実施例はちょうど逆方向（サーバー → クライアント）である。**

結果として:

1. **本研究が採った方向は、この特許の明細書が記述していない領域にある。** 「SSH + attestation は既に特許がある」で終わらせず、方向の違いを明示できる
2. 逆に言えば、**もし方向を変えていなかったら、この特許と正面衝突していた**。方向転換の判断は先行技術の観点からも妥当だったことになる
3. ただし**権利範囲はクレームで決まり、クレーム本文を取得できていない**。明細書が server → client しか書いていないことと、クレームがその方向に限定されていることは別問題である。**論文で先行技術として論じる前にクレームを読むこと**（未解決に記載）

### 設計で参考になる点（方向を反転させて読む）

- Evidence の中身の列挙（secure boot, ソフトウェアのログとチェックサム, trusted storage の証明, ハードウェア構成要素の完全性）は、本研究でクライアント端末の Claim Selection を決めるときの出発点になる。[[rfc9683-riv-tpm-network-devices]] の Code / Configuration / Credentials 3 分類と合わせて読める
- **再提示の契機の 3 分類**（periodic / on demand / triggering event such as PCR change）は、長時間 SSH セッション中の再 attestation（[[rfc4254-ssh-connection-protocol]] のグローバル要求や [[rfc4253-ssh-transport-layer]] §9 の rekey に乗せる案）の整理にそのまま使える。**特に "SSH rekey interval" を契機に挙げている点は、こちらが独自に到達した案と一致している**
- attestation 失敗時にセッションを即時終了する、という扱いも同じ

## 引用すべき箇所

> attestation technologies and schemes can be implemented for validating peering setup for critical (and other) infrastructure protocols, such as DHCP, DNS, SSH, etc.

> The SSH server can send, in addition to server credentials (e.g., public cryptographic key or digital certificate), the additional information to the SSH client to convey its own node/device integrity related data.

> The SSH client can review this attestation information and determine whether to continue or reject the SSH session establishment.

> Some of the above information can be continuously provided by the SSH server while the session is active. The information can be provided periodically, on demand (e.g., the SSH client requests such information again or SSH rekey interval) or in response to a triggering event (e.g., PCR change on SSH server).

> a nonce is a random number provided by the entity making the request. This nonce is passed into the TPM.

（※ いずれも Google Patents の HTML 版 <https://patents.google.com/patent/US11165861B2/en> から取得。**段落番号は未確認。** 正式に引用する前に USPTO の公報で段落番号を付けること）

## 未解決・気になる点

- **クレーム本文（独立クレーム 1 を含む）が未取得。** Google Patents の HTML からも取れなかった。権利範囲、特に方向（server → client に限定されているか）とプロトコル（SSH が独立クレームに現れるか）は**先行技術として論じる前に必ず確認すること**。USPTO 公報 PDF はダウンロードできたが画像 PDF でテキスト層がなく、OCR 手段が手元にない。**人間が PDF を開いてクレームを読むのが現状の最短経路**
- 継続出願 4 件（11570242 / 11652874 / 11882176 / 12363191）の内容。**継続出願でクレームが別方向（client → server）に拡張されている可能性がある。ここが本研究にとって最大のリスク**
- Abstract が取得できていない
- 明細書が SSH のどのメッセージに Evidence を載せると言っているか（具体的なプロトコル拡張の記述があるか、「追加情報を送る」という抽象的な記述に留まるか）
- Cisco がこれを実装・製品化した形跡があるか
- `docs/sources.md` に未確認として挙げていた 12132844 / 10621366 / 10169591 / 8856918 との関係（別系統と見られるが未確認）
