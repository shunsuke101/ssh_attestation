# 分野マップ — 自研究の立ち位置

> `/collect` と `/digest` で分かったことを、随時ここに畳んでいく。
> **論文の Related Work 節の下書き**として育てる。骨組みだけ先に置いてある。

最終更新: （未着手）

---

## 1. SSH のクライアント認証の現状と限界

| アプローチ | 何を保証するか | 限界 | 主要文献 |
|---|---|---|---|
| `publickey` 認証 | 秘密鍵の所持。署名対象に session identifier を含むのでセッションに束縛される | **端末が侵害されていないことを前提にしている**（RFC 4251 §9.4.4）。鍵の窃取・端末の改竄を検知できない | RFC 4252, RFC 4251 |
| `hostbased` 認証 | クライアント**ホスト**の鍵の所持 | 同じく「client has not been compromised」が前提で、緩和策は他方式との併用しかない（RFC 4251 §9.4.6） | RFC 4252 |
| SSH ユーザ証明書 (CA) | CA が発行時点で認めたこと | 発行後の端末状態は不問。server challenge による freshness がない | `draft-ietf-sshm-cert` |
| FIDO/U2F 鍵 (`*-sk`) | 鍵が特定のセキュリティキー内にあること（enrollment 時の attestation） | 鍵の常駐性だけで端末の状態は対象外。OpenSSH は attestation を opaque として扱い検証しない | OpenSSH `PROTOCOL.u2f` |
| `keyboard-interactive` + PAM | サーバー主導の汎用チャレンジ・レスポンス | 応答は UTF-8 文字列で session identifier への署名構造を持たない。クライアント側に特別なコードを要する機構は設計意図の外 | RFC 4256 |
| device attestation を組み込んだ SSH CA / 証明書 | 証明書発行時に端末の identity や鍵の常駐性を確認 | 発行時点の確認で、接続時の server challenge が無い。PCR 等の状態を appraisal しない実装が多い | `ssh-tpm-ca-authority`, `ssh-attest-proxy` |
| PAM での TPM platform attestation | 認証時に TPM で端末状態を検証 | SSH プロトコル外。challenge-response とセッション束縛が SSH のメッセージとして定義されていない。独自実装 | `HardwareProtectedSsh` |

→ **共通の欠落**: 「鍵の所持」は証明できるが、「接続元端末の状態」を**接続時点で、server の challenge に対して新鮮に**証明する標準的な手段がない。

（参考: サーバー認証側にも同型の欠落がある。TOFU + `known_hosts`、SSHFP、ホスト証明書はいずれも鍵の同一性までで、ホストの状態は保証しない。本研究の対象外だが対比として引ける。）

---

## 2. Remote Attestation の枠組み

- **標準アーキテクチャ**: RFC 9334 (RATS)。Attester / Verifier / Relying Party / Endorser の役割分担と、Background-Check / Passport の 2 モデル。→ `notes/specs/rfc9334-rats-architecture.md`
- **相互作用モデル**: Reference Interaction Models for Remote Attestation Procedures。Challenge/Response / Uni-Directional / Streaming の 3 モデルと、freshness を担う Handle。**本研究は Challenge/Response を採る。** → `notes/specs/draft-ietf-rats-reference-interaction-models.md`
- **TPM ベースの適用例**: RFC 9683 (RIV)。DevID / AK の鍵構成、Verifier の nonce による challenge-response、判定条件。→ `notes/specs/rfc9683-riv-tpm-network-devices.md`
- **Evidence 形式**: EAT、TPM Quote、TEE 固有形式（SEV-SNP report, TDX quote など）
- **信頼点**: TPM 2.0 / DICE / TEE
- **測定**: Measured Boot（起動時）、IMA/EVM（ファイル実行時）、Runtime Attestation（実行中）

---

## 3. 既存研究の分類軸

自研究を位置づけるための軸。収集が進んだら各セルを埋める。

### 軸 A: attestation を運ぶレイヤ

| 位置 | 例 | 長所 | 短所 |
|---|---|---|---|
| トランスポート層（KEX 内・`SSH_MSG_EXT_INFO`） | | 早期に検証、セッションに自然に束縛 | クライアント認証より前。server の challenge を明示的に送る往復が無く、鍵交換自体を challenge とみなすことになる |
| ユーザ認証層（新しい認証方式） | `keyboard-interactive` + PAM 型の実装（`HardwareProtectedSsh`） | **クライアント認証そのものの位置。server が方式固有メッセージで challenge を送り、client が認証要求で response を返せる**。多段認証（partial success）も既製 | 認証方式の新設が要る |
| 新規チャネル・グローバル要求 | | 互換性を保ちやすい。再 attestation に使える | 認証完了後なので、ログイン可否の判断には遅い |
| SSH 証明書の拡張フィールド | `ssh-attest-proxy`, `ssh-tpm-ca-authority` | 実装が軽い | 発行時点の状態に留まり、server challenge による freshness が無い |
| プロトコル外（サイドチャネル） | Keylime 型の別系統検証 | SSH を変えなくてよい | SSH セッションとの束縛が弱い |

### 軸 B: Verifier の配置

| 配置 | 例 | 長所 | 短所 |
|---|---|---|---|
| サーバー自身 | | 追加インフラ不要。Verifier と Relying Party が同居し、canonical な Challenge/Response になる | Reference Value の配布と更新が各サーバーで重い |
| 独立した検証サービス | | 集中管理できる | 可用性が接続の前提になる（Background-Check 型） |
| CA 兼務 | `ssh-tpm-ca-authority` | 既存の SSH CA 運用に載る | Passport 型になり、接続時の server challenge による freshness が弱まる |

### 軸 C: 対象方向

- **クライアント → サーバー**（接続元端末の状態証明 / device trust）: **本研究の対象**。商用先行
- **サーバー → クライアント**（接続先ホストの状態証明、TOFU の置き換え）: 対象外。対比として引く

### 軸 D: 測定の時点

- 起動時のみ（static）/ 実行中も（runtime）/ 定期再証明（periodic re-attestation）

---

## 4. 隣接分野

| 分野 | 関係 |
|---|---|
| Confidential Computing | attestation を前提技術として使う。Evidence 形式の参考 |
| Zero Trust / device posture | 商用実装が先行。要求仕様の根拠として引用可能 |
| Supply chain security (sigstore 等) | 「署名 + 検証ポリシ」の構造が似ている。Reference Value 管理の参考 |
| Network Access Control (802.1X, IDevID) | デバイス識別の先例 |

---

## 5. 自研究の主張（暫定）

> ここは収集が進むにつれて鋭くしていく。今は仮置き。

- **問題**: SSH のクライアント認証は鍵の所持証明に留まり、接続元端末の完全性をサーバーが検証できない（RFC 4251 §9.4.4 は端末が侵害されていないことを前提にしている）。
- **既存手法の不足**: （上の表が埋まったら書く）
- **提案**: attestation をクライアント認証に拡張する。RFC 9334 の役割、RFC 9683 の TPM ベースの Evidence、Reference Interaction Models の Challenge/Response に基づき、**server の challenge で freshness を担保し、client の response（TPM Quote）で client の完全性を server が検証する**。（軸 A のどの層に載せるか、軸 B の Verifier 配置、軸 D の測定時点は未決）
- **貢献**: （プロトコル設計 / 実装 / 評価のどれを主張するか）

---

## 6. 未解決の疑問

- SSH に attestation を載せた先行研究は実際にどれだけあるか？ 皆無なのか、あるが実装が無いのか。→ `/survey` で確認する
- IETF に SSH + attestation の Internet-Draft は存在するか？
- OpenSSH 開発陣は TPM 統合についてどういう立場か（ML を追う）
