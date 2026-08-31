# state — 収集の状態

## `seen.jsonl`

既読判定の唯一の情報源。1 行 1 JSON の**追記専用**ファイル。

**手で編集しないこと。** 既存行の書き換え・削除・並べ替えをすると既読判定が壊れ、過去に見たものが新着として再び出てくる。判定（`relevance` など）を変えたい場合は、同じ `id` の新しい行を追記して後勝ちで解釈する。

フィールドと `id` の正規化ルールは `../CLAUDE.md` を参照。

### 中身を見たいとき

```powershell
# 総件数
(Get-Content state\seen.jsonl | Measure-Object -Line).Lines

# high だけ一覧
Get-Content state\seen.jsonl | ConvertFrom-Json | Where-Object relevance -eq 'high' |
  Select-Object first_seen, type, title

# 特定日に追加された分
Get-Content state\seen.jsonl | ConvertFrom-Json | Where-Object first_seen -eq '2026-08-21'
```

### 壊してしまったら

行の重複や JSON 構文エラーがあると `/collect` が既読を取りこぼす。整合性の確認:

```powershell
$i = 0
Get-Content state\seen.jsonl | ForEach-Object {
  $i++
  try { $null = $_ | ConvertFrom-Json } catch { "行 $i が不正: $_" }
}
```
