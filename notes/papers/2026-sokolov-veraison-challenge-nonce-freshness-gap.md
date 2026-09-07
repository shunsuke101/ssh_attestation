---
id: "arxiv:2608.03534"
title: "A Challenge-Nonce Freshness Gap in Project Veraison's TPM Reference Schemes, Found by Appraising Application-Layer Action Evidence End-to-End"
authors: ["Anton Sokolov"]
year: 2026
venue: "preprint"
url: "https://arxiv.org/abs/2608.03534"
doi: null
type: paper
tags: [freshness, nonce, replay, tpm, veraison, rats, verifier, quote]
relevance: high
added: 2026-09-07
---

## 概要

RATS の参照実装である **Project Veraison** の TPM reference scheme が、**challenge-nonce の鮮度を検証していなかった**という欠陥を報告した論文。自律エージェントの行動記録（署名済みログ）を TPM quote に束縛するという応用を end-to-end で組んだ過程で発見された。再生された quote がそのまま `affirming`（肯定）と判定されてしまう。責任ある開示を経て上流に修正が取り込まれている（PR #432）。

## 手法・貢献

application-layer の action evidence を TPM の PCR に measure し、Veraison の verifier に通して end-to-end で appraise するパイプラインを構築。その過程で verifier の判定挙動を観察し、nonce 検証の欠落を特定した。

- 脅威モデル: 過去に正当だった quote を攻撃者が別セッションで再生する（replay）
- 前提とする信頼点: TPM 2.0、attestation key、PCR への measure
- 評価方法: 修正の前後で判定が変わることを実証。**同一の valid な quote が、自セッションでは `affirming`、新しいセッションに再生すると `contraindicated` に反転する**ことを示した
- 再現用アーティファクト: Zenodo, doi: 10.5281/zenodo.20998730

## 自研究との関係

（※ここは解釈）

- [x] **前提** — freshness を実装レベルで担保する難しさの実例として土台に使う
- [x] **背景** — Introduction で「freshness は仕様に書けば済む話ではない」と述べる根拠

`docs/scope.md` の「中心的な問い」のうち、**問い 4（Freshness をどう保証するか）に真正面から答えている。**

本研究にとっての含意は 2 つある。

**1. 仕様の正しさと実装の正しさは別だという実例。** RFC 9334 も SEAT 系 draft も nonce による freshness を当然の前提として書いている。しかしその参照実装が nonce を検証していなかった。SSH に attestation を載せる設計を書くとき、「session identifier `H` に束縛する」と仕様に一行書くだけでは不十分で、**検証側が実際にその束縛を照合していることをどう保証するか**まで踏み込む必要がある。[[draft-many-seat-architecture]] の束縛 3 条件のうち第 3 条件（binder を Evidence に焼き込む）は attester 側の話だが、この論文が突いたのは **relying party / verifier 側が本当に照合しているか**という裏側である。

**2. 「replay された quote が affirming になる」は本研究の脅威モデルの中核。** SSH の文脈に置き換えると、正常な状態のときに一度取得した quote を、その後改竄されたホストが再生し続けるという攻撃になる。これが通ると **attestation を足した意味が完全に消える**（TOFU 以下になる。TOFU は少なくとも鍵の変化には気づく）。したがって本研究では nonce と session binding の照合を、設計上の option ではなく **MUST として書くべき**だという論拠になる。

なお本論文の応用文脈（自律エージェントの行動記録）は本研究とは無関係。**引用すべきは欠陥の内容と、それが参照実装で起きたという事実であって、応用側ではない。**

## 引用すべき箇所

> does not enforce challenge-nonce freshness, so a replayed quote still appraises as affirming
> — arXiv:2608.03534, Abstract

> the same valid quote that is affirming in its own session flips to contraindicated when replayed to a fresh one
> — arXiv:2608.03534, Abstract

## 未解決・気になる点

- **査読前の preprint**。単著。引用するなら PR #432 が実在し上流にマージされたことを GitHub 側で直接確認すること（未確認）
- 欠陥が Veraison のどの層にあったのか（scheme 固有か、共通の appraisal ロジックか）。前者なら「実装の bug」、後者なら「アーキテクチャの落とし穴」で、引用時の主張の強さが変わる
- 他の RATS verifier 実装（Keylime 等 → [[gh-keylime]]）にも同種の欠落があるか。あるなら「参照実装の一件の bug」ではなく「この分野に共通する落とし穴」として、より強く書ける
- SSH の session identifier `H` を nonce の代わりに使う場合、TPM quote の `qualifyingData` に入れる形になるはず。サイズ制約（`H` はハッシュ長）を確認すること
