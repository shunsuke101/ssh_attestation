---
id: "arxiv:2610.06061"
title: "PRA-TLS: Attestation of a Client Application for TEE"
authors: ["Reina Sasaki", "Yutaka Ishikawa", "Atsuko Takefusa", "Masato Oguchi"]
year: 2026
venue: "arXiv preprint (cs.CR)"
url: "https://arxiv.org/abs/2610.06061"
doi: null
type: paper
tags: [client-attestation, tls, ra-tls, sgx, tee, attester-daemon, nonce, tamarin, formal-verification, runtime-attestation, enclave-boundary]
relevance: high
added: 2026-10-13
---

> **研究テーマを「attestation をクライアント認証に拡張する」に改めた直後に見つかった、同じ方向の最新研究。** 2026-10-05 投稿。

## 概要

TEE（Intel SGX）の enclave は attestation できても、**その enclave を呼び出すクライアントアプリケーション側は検証されない**という隙間を埋める提案。著者はお茶の水女子大学・ROIS・大妻女子大学・NII。

enclave は REE（Rich Execution Environment）側の untrusted なアプリケーションから呼ばれる。そのため enclave 自体が正当でも、境界をまたぐ引数・戻り値の改竄や、関数呼び出し順序の操作が成立する。論文はこれを **"even if an attacker invokes a legitimate enclave binary from a malicious client application, the enclave's attestation result may still be considered valid"** と表現する。

提案 **PRA-TLS (Portable Remote Attestation TLS)** は、**Attester Daemon** を信頼点として導入し、ホスト環境とアプリケーションコードを**実行時に**測定して Evidence にし、リモートの Verifier に検証させる。Verifier が期待状態と一致すると判定したときだけ enclave の処理を続行させる。

## 手法・貢献

- 脅威モデル: 悪意あるクライアントアプリケーションが正当な enclave を呼び出す。enclave 境界での引数・戻り値の改竄、呼び出し順序の操作。別の実行環境から取得した正当な Evidence を使い回すリレー攻撃
- 前提とする信頼点: Intel SGX の enclave、および **Attester Daemon**（それ自体も enclave）。前提として「起動後に Linux カーネルは改竄されない」ことを置く。TPM の物理的な取り外し・リセットは範囲外
- 評価方法: **Tamarin Prover による形式検証**（Evidence の完全性・真正性、再生／リレー攻撃耐性の lemma すべてが verified）＋ Intel SGX でのプロトタイプ実装と遅延測定

### プロトコルの要点

RA-TLS（[[2018-knauth-integrating-remote-attestation-with-tls]]）を拡張し、クライアントアプリケーションの attestation を **TLS ハンドシェイクに統合**する。Evidence は X.509 証明書の拡張に埋め込む。

| 要素 | PRA-TLS での実現 |
|---|---|
| challenge（nonce）の出所 | **Verifier（サーバー側）**。TLS の **ServerHello の random 値（server nonce）** をそのまま nonce として使う |
| Evidence の作り方 | Attester Daemon がクライアントアプリケーションのコードを測定し、**コードハッシュと nonce を連結してハッシュ**したものを Runtime Attestation Evidence とする |
| Verifier 側の検証 | 正当なコードの reference hash と nonce を同じ手順でハッシュし、期待値と比較する |
| 実行環境への束縛 | enclave の **sealing key** で nonce を暗号化し、Attester Daemon が返した暗号化 nonce と一致するかを確認する。両 enclave が同じ sealing key を導出できたことを示す（"Execution Environment Binding"）。これにより**別環境で取得した Evidence の持ち込みを防ぐ** |

### 測定された遅延

| 対象 | 中央値 | 平均 |
|---|---|---|
| PRA-TLS ハンドシェイク | **1301 ms** | 1257 ms |
| 素の TLS 1.3 ハンドシェイク | 2.758 ms | 2.729 ms |

環境は Intel Xeon Silver 4410Y (24 コア) / Ubuntu 22.04.5。内訳として、クライアント証明書を動的生成する場合の **RSA 鍵ペア生成が 171.1 ms、証明書生成全体で 172.6 ms** と報告されている。

## 自研究との関係

（※ここは解釈）

- [ ] **前提**
- [x] **競合** — 同じ「クライアント側の attestation をセキュアチャネルの認証に組み込む」問題を、TLS で解いている。差分を明示する必要がある
- [x] **部品** — nonce の作り方と束縛の構成は借用できる
- [x] **背景** — Introduction で「クライアント側 attestation の必要性は TLS 側でも 2026 年に提起された」と書ける

`docs/scope.md` の「中心的な問い」との対応: **問い 1・問い 4・問い 5 のすべてに具体的な答えを出している。**

### 構造が本研究のテーマとほぼ一致する

`CLAUDE.md` の研究テーマは「server からの challenge によって freshness を担保し、client からの response によって client の完全性を server が保証する」である。PRA-TLS はこれを TLS で実装している:

- server（Verifier）が ServerHello の random を challenge として出す
- client が `hash(コードハッシュ ‖ nonce)` を response として返す
- server が reference hash + nonce から期待値を計算して照合する

**つまり本研究は「PRA-TLS の SSH 版」として位置づけられてしまう危険がある。** 差分を明示的に作る必要がある。現時点で言える差分は 3 つ:

1. **信頼点が違う。** PRA-TLS は Intel SGX の sealing key に依存する。本研究は TPM 2.0 の AK と PCR Quote（[[tcg-tpm2-library-v185]]）を使う。TPM の方が普及しており、measured boot による起動時からの連鎖が取れる
2. **測定対象が違う。** PRA-TLS は「enclave を呼び出すアプリケーションのコード」を実行時に測定する。本研究は端末全体の起動時完全性（PCR）＋ SSH クライアントと鍵保護の状態
3. **プロトコルの受け皿が違う。** PRA-TLS は Evidence を X.509 証明書拡張に入れてハンドシェイク中に運ぶ。SSH にはユーザ認証層という「サーバーが challenge を送り、クライアントが応答する」ための正規の枠があり（[[rfc4252-ssh-authentication-protocol]]、先例は [[rfc4462-gssapi-ssh-auth-keyex]]）、証明書拡張に頼らずに済む

### nonce の取り方は本研究の論点と同じ場所に落ちる

PRA-TLS は **ServerHello の random をそのまま nonce に使っている。** これは本研究が [[rfc4253-ssh-transport-layer]] で検討した「鍵交換由来の値（cookie / exchange hash H）を Handle として使えるか」とまったく同じ構造の判断である。しかも [[draft-ietf-rats-reference-interaction-models]] §2.2 は「TLS nonce は Handle ではない」と明示的に切り分けている。

**PRA-TLS がこの点をどう正当化しているか（あるいは論じていないか）は、本研究の設計判断の根拠を作るうえで直接役に立つ。** Tamarin で検証しているので、少なくとも形式モデル上は replay/relay に耐えるとされている。**どのモデル化でそれが成り立っているかを精読する価値が高い**（未解決に記載）。

### 遅延の数字が問い 5 の比較基準になる

1301 ms 対 2.758 ms という比は厳しい。ただし内訳の大半が RSA 鍵ペア生成（171 ms）＋ SGX の Quote 生成であり、**TPM の Quote 生成コストと、鍵を毎回生成しない設計にすれば下げられる余地がある**。[[draft-usama-seat-intra-vs-post]] が報告する intra-handshake 140–1020 ms と同じ桁で、「intra-handshake は重い」という TLS 側の経験則を裏付ける数字がまた 1 つ増えた。

一方で、**SSH は TLS より接続頻度が桁違いに低くセッションが長い**という反論は依然有効（[[draft-usama-seat-intra-vs-post]] のノートに記録済み）。本研究の評価では、この数字を引いたうえで「SSH では許容できる」と論じる形になりそう。

### Future Work が本研究の論点と重なる

著者は今後の課題として、**オフライン環境のための Evidence 保存**、**再起動・クラッシュをまたいだ attestation の継続性と、古い Evidence の再利用防止**、**証明書署名に TPM 鍵を使うこと**を挙げている。3 つ目は本研究が最初から TPM を前提にする点と重なる。2 つ目は [[tcg-tpm2-library-v185]] の `TPMS_CLOCK_INFO`（resetCount / restartCount）で扱える論点で、**本研究の方が材料を持っている**。

## 引用すべき箇所

> Even if the enclave has been attested, the boundary between the enclave and the untrusted application poses risks, such as tampering with input arguments or return values and manipulating the order in which the application invokes functions. Therefore, it is necessary to establish the authenticity and integrity of not only the enclave itself but also the application and its execution environment.
> — Abstract

> even if an attacker invokes a legitimate enclave binary from a malicious client application, the enclave's attestation result may still be considered valid

> The Attester Daemon also measures the client application code and generates the Runtime Attestation Evidence by hashing the concatenation of the resulting code hash and the nonce.

> Through the TLS handshake, the TEE application sends a ClientHello message to the Verifier and receives a ServerHello message containing a nonce.

> Tamarin returned verified for all lemmas concerning evidence integrity and authenticity

（※ arXiv の HTML 版 <https://arxiv.org/html/2610.06061v1> から取得。**節番号・ページ番号は未確認。** 引用時に補うこと。`docs/sources.md` の注にあるとおり `arxiv.org/pdf/` 版は内容抽出に失敗するので HTML 版を使った）

## 未解決・気になる点

- **ServerHello の random を nonce として使うことの正当化を、論文がどう論じているか未確認。** 本研究の最大の設計論点と同じ場所なので、**ここは本文を精読する価値が最も高い**。Tamarin のモデルで nonce をどう抽象化しているかも確認したい
- Attester Daemon 自体の attestation をどう担保しているか（それも enclave だが、誰がいつ検証するのか）
- 「ホスト環境の測定」の具体（何をどう測るのか。IMA 相当の仕組みを使うのか、独自か）
- 査読の有無。arXiv preprint であり、投稿先が書かれているか未確認。**BibTeX には preprint として記録した**
- 日本の研究グループなので、国内会議（CSS / コンピュータセキュリティシンポジウム等）に関連発表がある可能性。**和文の先行発表があれば設計の細部が読める**
- SSH への言及は本文中に無い（確認済み）。つまり **TLS 側でクライアント attestation が提起されても、SSH は依然として空白**という本研究の立論は維持できる
