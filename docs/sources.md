# 巡回先レジストリ

> `/collect` はこのファイルを読んで巡回する。行を足せば収集範囲が広がる。
> `最終確認日` は `/collect` が更新する（人間が触らなくてよい）。
> `優先` = A: 毎回必ず / B: 毎回できれば / C: 月 1 回程度で十分。

---

## papers — 学術論文

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| A | **arXiv 検索（推奨経路）** | `https://arxiv.org/search/?searchtype=all&query=<キーワード>&start=0` | WebFetch。**動作確認済 2026-08-21** | 2026-08-21 |
| A | arXiv cs.CR 新着一覧 | `https://arxiv.org/list/cs.CR/recent` | WebFetch。**動作確認済 2026-08-21**（1 ページ 50 件） | 2026-08-21 |
| B | arXiv export API | `https://export.arxiv.org/api/query?search_query=cat:cs.CR+AND+all:%22remote+attestation%22&sortBy=submittedDate&sortOrder=descending&max_results=50` | Atom XML。**2026-08-21 時点で WebFetch から 429 が返る**（下記注参照）。使えたときだけ使う | — |
| A | IACR ePrint 新着 | `https://eprint.iacr.org/rss/rss.xml` / 検索は `https://eprint.iacr.org/search?q=attestation` | RSS + 検索。**検索は動作確認済 2026-08-21**（attestation で 215 件） | 2026-08-21 |
| B | USENIX Security 採録論文 | `https://www.usenix.org/conference/usenixsecurity<YY>/technical-sessions` | WebFetch。`<YY>` は開催年下 2 桁に読み替え | — |
| B | NDSS 採録論文 | `https://www.ndss-symposium.org/ndss<YYYY>/accepted-papers/` | WebFetch。年次で URL が変わる | — |
| B | ACM CCS 採録論文 | `https://www.sigsac.org/ccs/CCS<YYYY>/` から program へ | WebFetch。年次で構成が変わるので検索併用 | — |
| B | IEEE S&P 採録論文 | `https://sp<YYYY>.ieee-security.org/` から program へ | WebFetch。同上 | — |
| B | 汎用 Web 検索 | — | WebSearch で `docs/scope.md` のキーワードを回す。**2026-08-21 の初回で最も収穫が大きかった経路**（GitHub の実装 2 件はこれで発見） | 2026-08-21 |
| C | ACM DL / IEEE Xplore | `https://dl.acm.org/`, `https://ieeexplore.ieee.org/` | 検索 UI が JS 依存で取りにくい。WebSearch 経由で当たる方が確実 | — |

**注 1（arXiv）**: `export.arxiv.org` の API は共有 IP からのアクセスとみなされ **429 Too Many Requests** で弾かれることがある（2026-08-21 に確認）。**通常は `arxiv.org/search/` の HTML 検索を使う。** キーワード検索・新着一覧ともこちらで問題なく取得できる。API は取れたら儲けもの、程度に扱う。

**注 2**: 主要会議の採録リストは**年 1 回しか更新されない**。毎回叩く必要はなく、C 扱いで月 1 回、あるいは採録発表の時期（USENIX Sec は春〜夏に順次、NDSS は秋、CCS は夏〜秋）に見れば足りる。

---

## specs — 標準仕様・ドラフト

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| **A** | **IETF SSHM WG 文書一覧** | `https://datatracker.ietf.org/wg/sshm/documents/` | WebFetch。**最重要**。SSH を現に保守・拡張している WG。**動作確認済 2026-08-21** | 2026-08-21 |
| **A** | **sshm@ietf.org ML** | `https://mailarchive.ietf.org/arch/browse/sshm/` | WebFetch。**SSH に attestation / TPM の話題が出たことがあるか**を確認する（未巡回） | — |
| **A** | **IANA SSH Protocol Parameters** | `https://www.iana.org/assignments/ssh-parameters/ssh-parameters.xhtml` | WebFetch。メッセージ番号の空き枠と拡張名の登録状況。**拡張設計の一次情報。動作確認済 2026-08-21** | 2026-08-21 |
| **A** | **IETF SEAT WG 文書一覧** | `https://datatracker.ietf.org/wg/seat/documents/` | WebFetch。**最重要**。attestation を (D)TLS に束縛する WG。本研究の直接の隣接領域 | — |
| **A** | **IETF SEAT WG 憲章** | `https://datatracker.ietf.org/group/seat/about/` | WebFetch。**動作確認済 2026-08-21** | 2026-08-21 |
| **A** | **seat@ietf.org ML** | `https://mailarchive.ietf.org/arch/browse/seat/` | WebFetch。**SSH への適用が議論されたことがあるかを確認する**（未巡回） | — |
| A | IETF RATS WG 文書一覧 | `https://datatracker.ietf.org/wg/rats/documents/` | WebFetch。**動作確認済 2026-08-21**（RFC 8 本 + 現行 I-D 11 本） | 2026-08-21 |
| A | IETF datatracker 検索（attestation） | `https://datatracker.ietf.org/api/v1/doc/document/?name__contains=attestation&format=json&limit=50` | API (JSON)。**動作確認済 2026-08-21**（該当 184 件） | 2026-08-21 |
| A | IETF datatracker 検索（ssh） | `https://datatracker.ietf.org/api/v1/doc/document/?name__contains=ssh&format=json&limit=50` | API (JSON) | — |
| B | IETF secsh / SSH 関連 WG | `https://datatracker.ietf.org/wg/#sec` から SSH 関連を辿る | WebFetch。secsh WG は終了済みだが個人 I-D が出る | — |
| B | RFC Editor 新着 | `https://www.rfc-editor.org/search/rfc_search_detail.php?title=attestation` | WebFetch | — |
| B | TCG 仕様一覧 | `https://trustedcomputinggroup.org/resources/` | WebFetch。TPM 2.0 Library, DICE, RIM など | — |
| C | FIDO Alliance 仕様 | `https://fidoalliance.org/specifications/` | WebFetch。WebAuthn の attestation statement 形式 | — |
| C | W3C WebAuthn | `https://www.w3.org/TR/webauthn-3/` | WebFetch。改訂時のみ | — |
| C | Confidential Computing Consortium | `https://confidentialcomputing.io/` | WebFetch | — |

**注（datatracker API）**: `name__contains` は文書名の部分一致なので、`slides-*`（会議スライド）や `agenda-*` も大量に混ざる（2026-08-21 確認: attestation で 184 件、うち上位は大半がスライド）。**`draft-` と `rfc` で始まる名前だけを残すこと。** スライドは I-D の動きを追う目的では不要。

**押さえておくべき既存 RFC**（初回に `notes/specs/` へ入れる）: RFC 9334 (RATS Architecture), RFC 9711 系の EAT 関連, RFC 4251–4254 (SSH), RFC 4255 (SSHFP), RFC 8709 (Ed25519 in SSH)。番号は必ず現物で確認すること。

---

## impl — 実装・OSS 動向

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| A | OpenSSH リリースノート | `https://www.openssh.org/releasenotes.html` | WebFetch。**`openssh.com` は `openssh.org` に 301 するので `.org` を直接叩く**。動作確認済 2026-08-21（最新 10.5 / 2026-08-11） | 2026-08-21 |
| A | openssh-unix-dev ML | `https://marc.info/?l=openssh-unix-dev` | WebFetch。attestation / TPM / FIDO 関連スレのみ拾う | — |
| B | OpenSSH PROTOCOL 系ファイル | `https://raw.githubusercontent.com/openssh/openssh-portable/master/PROTOCOL{,.u2f,.agent,.sshsig,.key,.krl,.mux}` | raw を WebFetch。**動作確認済 2026-08-21**。de facto 標準の一次情報。ファイル一覧は `https://api.github.com/repos/openssh/openssh-portable/contents/` で確認 | 2026-08-21 |
| A | ssh-tpm-agent | `https://api.github.com/repos/Foxboron/ssh-tpm-agent/releases` | GitHub API。**動作確認済 2026-08-21**（最新 v0.9.0 / 2026-05-04） | 2026-08-21 |
| B | go-attestation | `https://api.github.com/repos/google/go-attestation/releases` | GitHub API | — |
| B | Keylime | `https://api.github.com/repos/keylime/keylime/releases` | GitHub API | — |
| B | Parsec | `https://api.github.com/repos/parallaxsecond/parsec/releases` | GitHub API | — |
| B | GitHub 横断検索 | `https://api.github.com/search/repositories?q=ssh+attestation+in:name,description&sort=stars&order=desc` | GitHub API。新規プロジェクトの発見用。**`in:readme` と `sort=updated` は使わない**（下記注） | 2026-08-21 |
| C | tpm2-software | `https://github.com/tpm2-software` | WebFetch。tpm2-tss / tpm2-tools のリリース | — |
| C | Linux IMA / integrity | `https://lore.kernel.org/linux-integrity/` | WebFetch。カーネル側の動き | — |
| C | sigstore | `https://api.github.com/repos/sigstore/sigstore/releases` | GitHub API。署名検証モデルの参考 | — |

**GitHub API の注意**: 未認証だと 60 req/hour。1 回の `/collect` で叩くのは上記程度に留める。403 が返ったら inbox に `レート制限で取得失敗` と記録して次に進む。

**注（横断検索のクエリ）**: 2026-08-21 に `q=ssh+attestation+in:name,description,readme&sort=updated` を試したところ、**total 3,851 件・上位は「今日 push された無関係リポジトリ」で埋まり、実質使い物にならなかった**。原因は (1) `in:readme` が「SBOM の sigstore attestation」等を大量に拾う、(2) `sort=updated` が関連度を完全に無視する、の 2 点。**`in:name,description` に絞り、`sort=stars` を使うこと。** なお 2026-08-21 に発見された有用な実装 2 件（`ssh-tpm-ca-authority`, `HardwareProtectedSsh`）は、いずれも GitHub 検索ではなく**汎用 Web 検索**経由で見つかった。実装の発見は Web 検索の方が当たりが良い。

---

## industry — 製品・業界動向

| 優先 | 名前 | URL | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| B | Teleport ブログ | `https://goteleport.com/blog/` | WebFetch。Device Trust / Machine ID が近い。**トップページには device trust 記事が出ないので、タグページ `https://goteleport.com/blog/tags/device-trust/` を直接見る方が良い**（次回試す） | 2026-08-21 |
| B | Tailscale ブログ | `https://tailscale.com/blog` | WebFetch。Tailscale SSH, device posture | 2026-08-21 |
| C | HashiCorp ブログ | `https://www.hashicorp.com/blog` | WebFetch。Boundary 関連のみ | — |
| C | Google Cloud Confidential Computing | `https://cloud.google.com/blog/products/identity-security` | WebFetch | — |
| C | AWS Nitro Enclaves | `https://aws.amazon.com/blogs/security/` | WebFetch。attestation document 関連 | — |
| C | Azure Attestation | `https://azure.microsoft.com/en-us/blog/` | WebFetch | — |
| C | Cloudflare ブログ | `https://blog.cloudflare.com/` | WebFetch。Access / device posture | — |

**注**: `industry` は最もノイズが多い。`docs/scope.md` の「ベンダのマーケティング記事」除外条件を厳しく当てること。原則 `relevance: medium` 以下で、**新プロトコル・新方式の初出だけ** `high` にする。

---

## 取得のコツ

- **API があるものは API を使う**（arXiv, datatracker, GitHub）。HTML スクレイプは構造変更で壊れる。
- 取得に失敗したソースは**黙って飛ばさず**、inbox に `- [取得失敗] <名前> — <理由>` として記録する。次回に持ち越せる。
- 1 回の `/collect` で全部を舐めようとしない。**優先 A を確実に、B を可能な範囲で、C は月 1 回**。
- 会議の採録リストは巨大なので、ページ全体を要約せず**キーワードに一致するタイトルだけ**を抜く。
