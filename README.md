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

## git 運用（OneDrive 内にリポジトリがあることの注意）

このフォルダは git 管理下にあり、**同時に OneDrive の同期対象でもある**。同期の担当が二重になっているので、次のルールを守らないと `.git` が壊れる。

### 守ること

1. **PC を切り替える前に、OneDrive の同期完了を必ず待つ。** タスクトレイの OneDrive アイコンがチェックマークになってから、別の PC で作業を始める。同期の途中で別 PC が触ると `.git/objects` が中途半端な状態で配られ、リポジトリが壊れる。
2. **こまめに push する。** ローカルにしかないコミットは OneDrive 事故で失われる。リモートは単なるバックアップではなく、**この構成における唯一の復旧手段**。
3. **このフォルダは「常にこのデバイス上に保持」に固定してある**（`attrib +P -U`）。解除しないこと。Files On-Demand が `.git` の中身を雲だけにすると git が動かなくなる。

### `.git` が壊れたら

```powershell
# 1. 壊れたフォルダを退避（消さない。未 push の変更が入っている可能性がある）
Rename-Item ssh_attestaion ssh_attestaion_broken
# 2. リモートから clone し直す
git clone <リモート URL> ssh_attestaion
# 3. 退避した方に未 push の変更があれば、ファイルを手でコピーして差分を確認する
```

### OneDrive が競合コピーを作ったら

`ファイル名-PC名.md` のようなファイルが増えていたら、OneDrive が競合を検出した印。`git log` と `git diff` で正しい方を判断し、手で解決してから競合コピーを削除する。**`state/seen.jsonl` の競合は特に慎重に**（追記専用なので、両方の追記行を残すのが原則）。

