---
id: "rfc:9683"
title: "Remote Integrity Verification of Network Devices Containing Trusted Platform Modules"
body: "IETF"
status: "Informational"
year: 2024
url: "https://www.rfc-editor.org/info/rfc9683"
type: spec
tags: [rats, riv, tpm, network-device, devid, ieee-802-1ar, iak, pcr-quote, charra, rim, coswid, peer-to-peer, asokan-attack]
relevance: high
added: 2026-09-09
---

## 何を規定しているか

TPM を積んだネットワーク機器（ルータ・スイッチ・ファイアウォール）について、そのファームウェアとソフトウェアの完全性を遠隔検証するワークフロー **RIV (Remote Integrity Verification)** を定めた Informational RFC（2024-12）。著者は G. C. Fedorkow (Ed., Juniper Networks), E. Voit (Cisco), J. Fitzgerald-McKay (NSA)。

新しいプロトコルは一切定義しない。**既存標準の組み合わせ方（プロファイル）を与えるだけ**の文書である。組み合わせるのは IEEE 802.1AR DevID、TCG の PCR / Quote / イベントログ、RFC 9684 (CHARRA YANG)、RIM / CoSWID。

執筆動機がはっきり書かれている: RFC 9334 と RATS のユースケース文書は抽象的すぎて、「機器ベンダと運用者が相互運用可能な機器を設計・製造・配備する」には指針が足りない。その空白を埋めるのが本 RFC の意図（§1）。

## 本研究に効く定義・要件

| 節 | 内容 | どう使うか |
|---|---|---|
| §1.5 | attestation は **Device Identity** と **Software Measurement** の 2 つが噛み合って初めて成立する | 問題設定の言い換えに使える。**SSH のホスト鍵／クライアント鍵は前者しか担保していない**、という本研究の出発点をこの RFC の語彙で言える |
| §1.6 | "Lying Endpoint" 問題 — 悪意あるソフトが本来の機能を破壊し、かつ自分が侵害されたことを報告させない | 脅威モデル節でそのまま引ける |
| §2.1.1 表 1 | PCR 割当。測定対象を **Code / Configuration / Credentials** の 3 クラスに分ける | Claim Selection の設計に直結。特に Credentials クラスの発想は後述 |
| §2.2 | DevID 鍵と AK（Attestation Key）を**分ける**。両方 TPM で保護すること (MUST)。AK 証明書は DevID 証明書と同じ subject / 同じシリアル・同じ CA 署名 | 鍵設計の必須要件。分けない設計は §5.2 の攻撃で落ちる |
| §2.3 | 情報フロー Step 0（RIM 配布）/ Step 1（Verifier が要求）/ Step 2（Attester が DevID + Quote + 任意で RIM を返す）と、相互運用のための 6 つの MUST | SSH に写すときの「最低限そろえる部品」リスト |
| §3.1.3 | Verifier は Appraisal Policy for Evidence を持たなければならない (MUST) が、**その形式も伝達方法も本 RFC は規定しない** | 問い 3（Verifier をどこに置くか）で自由に設計できる部分 |
| §3.2 | Challenge-Response の参照モデル。[[draft-ietf-rats-reference-interaction-models]] §7.1 から導出したと明記。RFC 9334 Appendix A の time(VG) / time(NS) / time(EG) / time(RG,RA) / time(RX) を図に対応づける | 時刻モデルつきのフロー図。本研究のシーケンス図の下敷きになる |
| §3.2 Step 5 | Verifier が **SHOULD NOT trust** とする条件が 6 つ列挙されている（署名不一致 / nonce 不一致 / PCR とログの不一致 / ログが known good でない / Appraisal Policy 不適合 / `time(RG)-time(NS)` が閾値超え＝ stale） | そのまま SSH 側の判定条件に写せる。**最後の 1 つが問い 4（freshness）の実務的な答えの形** |
| §3.2.1 | 転送は NETCONF / RESTCONF、いずれも secure tunnel の上で | 後述の通り、ここが本研究との分岐点 |
| §3.3 | **Centralized vs. Peer-to-Peer**。2 台のルータが互いに Attester 兼 Verifier になる構成。各機器が自分の RIM と、相手ごとの Appraisal Policy と、信頼する X.509 root を自前で持ち運ぶ必要がある | 本研究の構図に一番近い節。詳細は out of scope とされている＝空白 |
| §5.1 | **"RIV uses the DevID to validate a TLS or SSH connection to the device as the attestation session begins."** | 本 RFC が SSH に言及する唯一の箇所。後述 |
| §5.2 | なりすまし 3 パターン（機器ごと / 正当な DevID で他機の Quote を流用 / OS 侵害で偽 Quote）。DevID と AK を分け、AK 証明書を DevID と同一 subject で結ぶことで **Asokan 型 PITM (RFC 6813)** を防ぐ | 鍵を分ける理由の一次出典 |
| §5.3 | 再生攻撃は Verifier が毎回新しい random nonce を送り、TPM が Quote にそれを含めて署名することで防ぐ。TUDA が request/response なしの代替 | 問い 4 の標準解と、その代替の在り処 |

### nonce のサイズ

TPM 1.2 / 2.0 とも nonce は digest サイズまで（20 または 32 バイト）取れる（§3.2 Step 2）。SSH メッセージに載せる場合の実サイズ見積もりに使える。

## 拡張点・自由度

意図的に規定していない部分＝本研究が入り込める余地:

- **Appraisal Policy の形式と伝達方法**（§3.1.3）
- **Relying Party と Verifier の間のやりとり**（§2.3 で明示的に out of scope）
- **Peer-to-Peer の詳細**（§3.3）。802.1X / 802.1AE / EAP / LLDP が「適した方法」として名前だけ挙がるが、それ以上は書かれていない
- Run-Time Attestation、仮想化・コンテナ、スリープ状態、マルチベンダ複合機器（§1.7.1 でいずれも out of scope）

逆に、本研究が**引き継げない**割り切りもある:

- RIV は **"for use in non-privacy-preserving applications"** を明言（§1.7）。だから Privacy CA も TCG Platform Certificate も要らない、としている
- NETCONF / YANG を前提にしている（§1.7）
- TPM またはその互換暗号プロセッサを必須としている（§1.7）

## 他仕様との関係

- 参照している: RFC 9334（アーキテクチャ）、RFC 9684（CHARRA YANG、Quote 取得の実体）、[[draft-ietf-rats-reference-interaction-models]]（§3.2 の参照モデルの出典）、IEEE 802.1AR（DevID）、TCG PC Client Platform Firmware Profile / CEL / RIM、RFC 9393（CoSWID）、RFC 8572（SZTP）、RFC 8995（BRSKI）、RFC 6813（Asokan 攻撃）、TUDA
- 参照されている: [[draft-ietf-rats-reference-interaction-models]] §9 が「TPM ベースの remote attestation では RFC 9683 §5 の security considerations も考慮せよ」と指す
- 競合・重複: なし。RIV はネットワーク機器向けの**適用プロファイル**であって、一般的な attestation プロトコルではない

## 引用すべき箇所

> RIV uses the DevID to validate a TLS or SSH connection to the device as the attestation session begins. Security of this process derives from TLS or SSH security, with the DevID, which contains a device serial number, providing proof that the session terminates on the intended device.
> — RFC 9683, §5.1

> RIV must address the "Lying Endpoint" problem, in which malicious software on an endpoint may subvert the intended function and also prevent the endpoint from reporting its compromised status.
> — RFC 9683, §1.6

> In a peer-to-peer application such as two routers negotiating a trust relationship, the two peers can each ask the other to prove software integrity. In this application, the information flow is the same, but each side plays a role both as an Attester and a Verifier.
> — RFC 9683, §3.3

> RIV provides no direct link between the time at which the event takes place and the time that it's attested
> — RFC 9683, §3.2 Step 1

## 自研究との関係

（※ここは解釈）

**この RFC は SSH を「attestation セッションを運ぶ土管」としてしか見ていない。** §5.1 の位置づけを分解するとこうなる:

1. DevID 証明書で TLS / SSH セッションが意図した機器で終端していることを確かめる
2. **そのうえで** NETCONF / RESTCONF (§3.2.1) を張り、CHARRA YANG モデルで Quote を取りに行く

つまり attestation は SSH の**外側**にあり、SSH のホスト認証そのものは静的鍵のまま何も変わらない。RIV にとって SSH は RFC 4253 として一度参照されるだけの前提である。**本研究が埋めるのはまさにこの穴**——attestation を SSH の外の管理プロトコルに置くのではなく、SSH の認証そのものに組み込む。RFC 9683 は「先行研究」ではなく「対比対象」として引くのが正しい使い方だと思われる。

**§3.3 peer-to-peer は構造が本研究に近い。** 各ピアが Attester 兼 Verifier になり、中央権威に問い合わせずに済むよう RIM と Appraisal Policy を自前で持つ、という設計。本研究の方向（Attester = SSH クライアント、Verifier / Relying Party = SSH サーバー自身）はこの片方向版にあたる。「各ピアが Reference Value を持ち運ばねばならない」という指摘は問い 5（大規模運用時の Reference Value 管理）そのもので、RIV 自身がここを out of scope にしている以上、本研究で正面から扱う価値がある。

**§2.1.1 の Credentials クラスが面白い。** 「Root of Trust の外にある公開鍵や資格情報が改竄されていないことを attestation で確認したい」という発想は、SSH に持ち込むと `authorized_keys` やホスト鍵そのものを測定対象にすることを意味する。attestation で守る対象に「鍵ファイルの完全性」が入るなら、TOFU の弱点を別角度から潰せる。問い 1（どのレイヤに載せるか）とは独立に検討できる論点。

**プライバシーの割り切りは引き継げない。** RIV は相手がルータだから "non-privacy-preserving" で済ませているが、本研究は SSH クライアント端末を Attester にする方向を採った。個人が使う端末に DevID 相当の一意識別子を持たせて毎回サーバーに提示させるのは、そのままではプライバシー問題になる。DAA 系（seen.jsonl の `draft:ietf-rats-daa-09`）を一度見る必要がある。

## 未解決・気になる点

- **RFC 9684 (CHARRA YANG) 本体が未読。** Quote とイベントログを運ぶデータモデルの具体（どのノードに何を入れるか）を SSH メッセージに写せるかは未確認。RIV の実装可能性はほぼこの RFC に載っている
- Appendix A（TPM を使った attestation の解説、RTM、レイヤリングモデル、実装ノート）は未読
- §2.1.2（PCR 割当の注記）と §2.4（simplifying assumptions）は流し読み。RIM の入手経路が「機器自身に同梱」でもよいという点は問い 5 に効きそうなので後で精読
- §3.2 Step 1 の「測定が起きた時刻と attestation された時刻を直接結ぶ手段を RIV は持たない」という自己申告。SSH ハンドシェイクに載せる場合、このギャップ（TOCTOU）をどう扱うか。streaming attestation なら解けると書いてあるが、それは単発接続の SSH と相性が悪い
