# 分野マップ — 自研究の立ち位置

> `/collect` と `/digest` で分かったことを、随時ここに畳んでいく。
> **論文の Related Work 節の下書き**として育てる。骨組みだけ先に置いてある。

最終更新: （未着手）

---

## 1. SSH のホスト認証の現状と限界

| アプローチ | 何を保証するか | 限界 | 主要文献 |
|---|---|---|---|
| TOFU + `known_hosts` | 2 回目以降の鍵の同一性 | 初回接続が無防備。ホスト鍵漏洩・ホスト改竄を検知できない | RFC 4251 |
| SSHFP (DNS) | DNS 権威が主張する鍵 | DNSSEC 前提。鍵の同一性までで、ホストの状態は保証しない | RFC 4255 |
| SSH Certificate (CA) | CA が発行時点で認めたこと | 発行後のホスト状態は不問。CA が単一障害点 | OpenSSH 仕様 |
| FIDO/U2F 鍵 (`*-sk`) | 鍵が特定のセキュリティキー内にあること | **クライアント側**の鍵保護。ホスト側の状態は対象外。ただし attestation を SSH で扱う既存の前例として重要 | OpenSSH 8.2+ |

→ **共通の欠落**: 「鍵の所持」は証明できるが「マシンの状態」は証明できない。

---

## 2. Remote Attestation の枠組み

- **標準アーキテクチャ**: RFC 9334 (RATS)。Attester / Verifier / Relying Party / Endorser の役割分担と、Background-Check / Passport の 2 モデル。→ `notes/specs/`
- **Evidence 形式**: EAT、TPM Quote、TEE 固有形式（SEV-SNP report, TDX quote など）
- **信頼点**: TPM 2.0 / DICE / TEE
- **測定**: Measured Boot（起動時）、IMA/EVM（ファイル実行時）、Runtime Attestation（実行中）

---

## 3. 既存研究の分類軸

自研究を位置づけるための軸。収集が進んだら各セルを埋める。

### 軸 A: attestation を運ぶレイヤ

| 位置 | 例 | 長所 | 短所 |
|---|---|---|---|
| トランスポート層（KEX 内） | | 早期に検証、セッションに自然に束縛 | プロトコル変更が大きい |
| ユーザ認証層 | | 既存の拡張点を使える | 検証がハンドシェイク後半 |
| 新規チャネル | | 互換性を保ちやすい | 接続確立後なので手遅れになりうる |
| SSH 証明書の拡張フィールド | | 実装が軽い | 発行時点の状態に留まる |
| プロトコル外（サイドチャネル） | Keylime 型の別系統検証 | SSH を変えなくてよい | SSH セッションとの束縛が弱い |

### 軸 B: Verifier の配置

| 配置 | 例 | 長所 | 短所 |
|---|---|---|---|
| クライアント自身 | | 追加インフラ不要 | Reference Value の配布と更新が重い |
| 独立した検証サービス | | 集中管理できる | 可用性が接続の前提になる |
| CA 兼務 | | 既存の SSH CA 運用に載る | Passport 型になり freshness が弱まる |

### 軸 C: 対象方向

- **ホスト → クライアント**（接続先の状態証明）: 本研究の主眼
- **クライアント → ホスト**（接続元端末の状態証明 / device trust）: 商用先行

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

- **問題**: SSH のホスト認証は鍵の所持証明に留まり、ホストの完全性を検証できない。
- **既存手法の不足**: （上の表が埋まったら書く）
- **提案**: （軸 A/B/C/D のどこを選ぶか。選択の根拠は？）
- **貢献**: （プロトコル設計 / 実装 / 評価のどれを主張するか）

---

## 6. 未解決の疑問

- SSH に attestation を載せた先行研究は実際にどれだけあるか？ 皆無なのか、あるが実装が無いのか。→ `/survey` で確認する
- IETF に SSH + attestation の Internet-Draft は存在するか？
- OpenSSH 開発陣は TPM 統合についてどういう立場か（ML を追う）
