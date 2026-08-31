# SSH Attestation — 情報収集ノート

SSH に attestation（機器証明）機能を実現する研究のための、情報収集・蓄積フォルダ。

## 使い方

Claude Code をこのフォルダで起動して、以下を叩く。

| コマンド | 何をするか |
|---|---|
| `/collect` | 全カテゴリを巡回し、**前回以降の新着だけ**を拾う |
| `/collect papers` | 論文だけ。`specs` / `impl` / `industry` も同様 |
| `/digest` | 当月の収集結果を月次ダイジェストに畳む（`/digest 2026-07` で月指定） |
| `/survey <トピック>` | 定期収集とは別に、特定テーマを単発で深掘りする |

推奨リズム: **`/collect` を週 1 回、`/digest` を月末に 1 回。**

## 流れ

```
docs/scope.md      巡回のキーワードと除外条件  ┐
docs/sources.md    巡回先のリスト              ┘── 手で育てる設定
        │
        ▼  /collect
state/seen.jsonl   既読 ID と突き合わせて新着だけ残す
        │
        ▼
inbox/YYYY-MM-DD.md   その日の新着一覧（雑・使い捨て）
        │
        ▼  relevance: high のものだけ
notes/{papers,specs,impl,industry}/   精読ノート（1 件 1 ファイル・永続）
related-work/bibliography.bib         BibTeX（論文執筆にそのまま流用）
        │
        ▼  /digest
digests/YYYY-MM.md          月次のまとめと自研究への示唆
related-work/landscape.md   分野の分類マップと自分の立ち位置
```

肝は 2 つ。

1. **`inbox`（速い・雑）と `notes`（遅い・精査）を分ける。** 拾った全部を精読ノート化すると続かない。
2. **`state/seen.jsonl` で既読を潰す。** 何度 `/collect` しても、既に見たものは二度と出てこない。

## 最初にやること

`docs/scope.md` と `docs/sources.md` に目を通し、研究の方向に合わせて**キーワードと除外条件を自分の言葉で書き直す**。ここの精度がそのまま収集のノイズ量になる。巡回先も、自分が普段見ているサイトを足していく。

## 手を入れてよい場所 / いけない場所

- **自由に編集**: `docs/`、`notes/`、`digests/`、`related-work/landscape.md`
- **追記のみ**: `state/seen.jsonl`、`related-work/bibliography.bib` — 既存行を書き換えると既読判定と引用が壊れる
- **消してよい**: `inbox/` — 生ログなので、`/digest` を回した後の古い月は消して構わない
