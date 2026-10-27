# 巡回先レジストリ

> `/collect` はこのファイルを読んで巡回する。行を足せば収集範囲が広がる。
> `最終確認日` は `/collect` が更新する（人間が触らなくてよい）。
> `優先` = A: 毎回必ず / B: 毎回できれば / C: 月 1 回程度で十分。

---

## papers — 学術論文

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| A | **arXiv 検索（推奨経路）** | `https://arxiv.org/search/?searchtype=all&query=<キーワード>&start=0` | WebFetch。**動作確認済 2026-09-14**。**検索語は `SSH attestation` ではなく `attested TLS` を主軸にすること**（2026-09-14: 前者は既読 2 件のみで枯れている／後者は新規 3 件 + 土台文献 1 件を拾った）。`remote attestation TPM host authentication` は 1 件しか返らず使えない。**2026-10-26: `attested TLS` は新規ゼロ、代わりに `remote attestation TPM` + `&order=-announced_date_first` で `2609.20909`（TPM-Attest）を拾った。新着順ソートを併用すること** | 2026-10-26 |
| A | arXiv 本文の読み方 | `https://arxiv.org/html/<ID>v1` | WebFetch。**`arxiv.org/pdf/<ID>` は PDF バイナリが読めず内容抽出に失敗する**（2026-09-14 に 2 件で確認）。ノート作成のための精読は必ず `/html/` 版を使うこと | 2026-10-13 |
| A | arXiv cs.CR 新着一覧 | `https://arxiv.org/list/cs.CR/recent` | WebFetch。**動作確認済 2026-09-14**（1 ページ 50 件）。ただし該当は 1 件程度で、キーワード検索の方が効率がよい。2026-10-26: 263 件中の先頭 50 件に該当なし | 2026-10-26 |
| B | arXiv export API | `https://export.arxiv.org/api/query?search_query=cat:cs.CR+AND+all:%22remote+attestation%22&sortBy=submittedDate&sortOrder=descending&max_results=50` | Atom XML。**2026-08-21 時点で WebFetch から 429 が返る**（下記注参照）。使えたときだけ使う。**2026-10-26 は 429 にならず取得できた**（30 件） | 2026-10-26 |
| B | IACR ePrint 新着 | `https://eprint.iacr.org/rss/rss.xml` / 検索は `https://eprint.iacr.org/search?q=attestation` | RSS + 検索。**検索は動作確認済 2026-09-14**。上位はほぼ ZK / ブロックチェーン / MPC で収穫は薄い（2026-09-14 も 25 件中、拾えたのは `2026/755 ACTS` の 1 件のみ）。優先 B 据え置き。2026-10-26 も新規該当なし | 2026-10-26 |
| B | USENIX Security 採録論文 | `https://www.usenix.org/conference/usenixsecurity<YY>/technical-sessions` | WebFetch。`<YY>` は開催年下 2 桁に読み替え。2026-10-26: usenixsecurity26 は約 62 万字あり、先頭 10 万字だけ確認した。`offset` で続きを読むこと | — |
| B | NDSS 採録論文 | `https://www.ndss-symposium.org/ndss<YYYY>/accepted-papers/` | WebFetch。年次で URL が変わる。2026-10-26: NDSS 2026 の採録一覧を全件確認（約 20 万字を `offset` で 2 回に分けて読む） | 2026-10-26 |
| B | ACM CCS 採録論文 | `https://www.sigsac.org/ccs/CCS<YYYY>/` から program へ | WebFetch。年次で構成が変わるので検索併用 | — |
| B | IEEE S&P 採録論文 | `https://sp<YYYY>.ieee-security.org/` から program へ | WebFetch。同上 | — |
| A | 汎用 Web 検索 | — | WebSearch で `docs/scope.md` のキーワードを回す。**2026-08-21 の初回で最も収穫が大きかった経路**（GitHub の実装 2 件はこれで発見）。2026-09-07 は**米国特許 11165861（SSH サーバ認証時に完全性情報を送る方式）**を拾った。**2026-09-14 は `"attested SSH" OR "SSH attestation" protocol design 2026` で AsiaCCS 2026 の Identity Crisis 論文を発見**（arXiv にも ePrint にも無く、この経路でしか出てこなかった）。**特許も査読付き会議論文も他経路に出てこないので Web 検索は必須。A に昇格**。**2026-10-19 は `"attested SSH" OR "SSH attestation" protocol design` で Cisco の別ファミリー US 11321465 / 11934525（クライアント → サーバー方向）と FOSDEM 2025 の TDX-in-SSH 講演を発見**。2026-10-26 は Foxboron の `attezt`（ACME device-attest-01）と TCG advisory VRT0010（CVE-2026-6726）を拾った | 2026-10-26 |
| C | ACM DL / IEEE Xplore | `https://dl.acm.org/`, `https://ieeexplore.ieee.org/` | 検索 UI が JS 依存で取りにくい。WebSearch 経由で当たる方が確実 | — |
| **A** | **米国特許（先行技術）** | HTML は `https://patents.google.com/patent/US<番号>B2/en`（**こちらを先に使う**） / 実体 PDF は `https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/<特許番号>` | **2026-10-13 に US 11165861 の一次確認に成功（3 回目で初成功）。A に昇格。** 経路の知見: **`patents.google.com` の HTML を WebFetch するのが正解**（明細書本文が読める）。**USPTO の PDF は curl でダウンロードできるが画像 PDF でテキスト層が無く `pdftotext` では中身が取れない**（11165861 / 11882176 で確認。12363191 は HTTP 504）。**クレーム本文は Google Patents の HTML からも取得できていない**ので、権利範囲の確認は人間が PDF を開く必要がある。<br>**確認済み**: US 11165861 B2（Cisco、SSH + attestation、サーバー → クライアント方向）→ `notes/papers/2021-sheth-cisco-attestation-peering-ssh.md`。**同ファミリーの継続出願 US 11570242 / 11652874 / 11882176 / 12363191 は未確認（本研究にとって最大の先行技術リスク）。** 別系統として未確認: 12132844, 10621366, 10169591, 8856918。<br>**2026-10-19 追加・最優先で一次確認**: **US 11321465 B2 / 継続 US 11934525 B2 "Network security by integrating mutual attestation"（Cisco、同じ発明者陣）。検索スニペットでは SSH でサーバーがクライアントの trust level を判定する＝本研究と同じクライアント → サーバー方向**。2026-10-19 は WebFetch 権限拒否で一次情報未読。**2026-10-26 も patents.google.com・freepatentsonline.com とも権限拒否（3 回連続の持ち越し）。人間が確認するか、ドメインを許可すること**。**2026-10-26 午後の手動の再実行では patents.google.com の WebFetch が通り、US 11321465 / 11934525 の明細書の SSH の節とクレームを読めた** → `notes/papers/2022-sheth-cisco-mutual-attestation-ssh.md`。**クレームは HTML の末尾（`offset` 200000 付近）にある** | 2026-10-26 |
| A | arXiv 検索（並行テーマ） | `https://arxiv.org/search/?searchtype=all&query=<キーワード>&start=0&order=-announced_date_first` | WebFetch。**並行テーマ（NETCONF / YANG による remote attestation）用。2026-10-26 追加・未巡回。** 検索語は `NETCONF attestation` / `YANG attestation` / `TPM quote verification` / `remote attestation verifier` から始め、収穫を見て `docs/scope.md` の並行テーマのキーワードに広げる。2026-10-26 初巡回: `NETCONF attestation` は 0 件、`YANG attestation` は著者名 Yang に当たってノイズのみ、`TPM quote verification` は 1 件、`remote attestation verifier` は 84 件（2 ページ） | 2026-10-26 |
| A | 汎用 Web 検索（並行テーマ） | — | WebSearch で `docs/scope.md` の「並行テーマ（必ず回す）」のキーワードを回す。**主テーマの行とは別に回すこと**（掛け方は `docs/scope.md` の「検索式の組み方」）。2026-10-26 追加・未巡回。2026-10-26 初巡回: Cisco IOS XR の独自 YANG、I2NSF の YANG draft、TrustCom 2025 の Eckel ら、Ryan Hurst の記事を発見 | 2026-10-26 |
| C | ネットワーク管理系の会議（IEEE NOMS / CNSM / IFIP/IEEE IM） | — | WebSearch で `NETCONF attestation NOMS` のように会議名を掛ける。IEEE Xplore は検索 UI が JS 依存なので直接は叩かない。NETCONF / YANG の attestation 論文はセキュリティ系の会議よりこちらに出やすいという見込み（未確認）で追加。2026-10-26 追加・未巡回。2026-10-26: 会議名を掛けた検索では該当論文なし | 2026-10-26 |

**注 1（arXiv）**: `export.arxiv.org` の API は共有 IP からのアクセスとみなされ **429 Too Many Requests** で弾かれることがある（2026-08-21 に確認）。**通常は `arxiv.org/search/` の HTML 検索を使う。** キーワード検索・新着一覧ともこちらで問題なく取得できる。API は取れたら儲けもの、程度に扱う。

**注 2**: 主要会議の採録リストは**年 1 回しか更新されない**。毎回叩く必要はなく、C 扱いで月 1 回、あるいは採録発表の時期（USENIX Sec は春〜夏に順次、NDSS は秋、CCS は夏〜秋）に見れば足りる。

---

## specs — 標準仕様・ドラフト

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| **A** | **IETF SSHM WG 文書一覧** | `https://datatracker.ietf.org/wg/sshm/documents/` | WebFetch。**最重要**。SSH を現に保守・拡張している WG。**動作確認済 2026-09-14**。**必ず「Related Internet-Drafts」欄まで個別に列挙させること**（2026-09-14 にここだけで新規 9 件。要約させると "9 additional drafts" と畳まれて中身が消えるので、「一つずつ列挙せよ」と明示的に指示する）。WG 文書欄だけ見ていると個人 I-D を丸ごと落とす。**2026-10-13 時点では Related 欄に RFC 4250–4256 / 4335 / 4344 / 4419 / 4462 / 4716 / 4819 も並ぶ**（ここで `rfc:4462` を発見した。SSH に認証方式を追加した先例で `high` 判定 → `notes/specs/rfc4462-gssapi-ssh-auth-keyex.md`）。新規 I-D は `draft-kario-gss-keyex-pqc-00` のみ。2026-10-19 は `draft-prabel-ssh-scloudplus-kex-00` のみ。2026-10-26 は新規なし | 2026-10-26 |
| **A** | **ssh@ietf.org ML（SSHM WG のリスト）** | `https://mailarchive.ietf.org/arch/browse/ssh/` | WebFetch。**2026-10-13 に初めて取得成功。** 3 回連続の失敗は**リスト名を間違えていたため**で、SSHM WG のメーリングリストは `sshm@ietf.org` ではなく **`ssh@ietf.org`**（datatracker の WG ページ `https://datatracker.ietf.org/group/sshm/about/` の Personnel 欄で確認）。件名は `[Ssh]` で始まる。**`/arch/search/?email_list=ssh&q=attestation` は依然 403 なので browse 経路を使うこと**（seat でも同じ症状）。2026-10-13 時点で直近 40 通に attestation / TPM / device trust のスレッドは無し＝本研究の空白の一次的裏付けになる。関連スレッド: "KEM-based user authentication for post-quantum SSH"（ユーザ認証方式の追加議論）、"hash standins for full public keys"（Damien Miller 発起）、"Formally Modelling the Terrapin Attack on SSH"。**2026-10-19: chair（Farrell）が "zero trust discussion" で「draft を出して採択を求めよ、実装者の支持がなければ見込み薄」と回答**（device trust 系提案に対する WG の温度感の一次情報） | 2026-10-26 |
| **A** | **rats@ietf.org ML** | `https://mailarchive.ietf.org/arch/browse/rats/` | WebFetch。**未巡回（2026-10-13 に巡回先として追加）。** `draft-reddy-rats-key-binding`（→ `notes/specs/draft-reddy-rats-key-binding.md`）のような個人提出 I-D の議論状況を追うのに要る。**2026-10-19 に初巡回・取得成功**（browse 形式で 40 通。SSH / key binding の言及なし）。2026-10-26 は TPM 内鍵生成の証明方式へのレビュー依頼スレッド（Drake）を観察 | 2026-10-26 |
| **A** | **IANA SSH Protocol Parameters** | `https://www.iana.org/assignments/ssh-parameters/ssh-parameters.xhtml` | WebFetch。メッセージ番号の空き枠と拡張名の登録状況。**拡張設計の一次情報。動作確認済 2026-09-14**（ページ最終更新 2026-09-08。Extension Names は 5 件のままで新規なし。空き枠は 9–19 / 22–29 / 54–59、Reserved は 30–49 / 128–191 / 192–255） | 2026-10-26 |
| **A** | **IETF SEAT WG 文書一覧** | `https://datatracker.ietf.org/wg/seat/documents/` | WebFetch。**最重要**。attestation を (D)TLS に束縛する WG。本研究の直接の隣接領域。**動作確認済 2026-09-14**（WG doc 1 本 + 関連 individual draft 7 本で**前回から変化なし、全件既読**）。2026-09-07 の `high` 5 件中 4 件がここ由来だったが、いったん出尽くした模様 | 2026-10-26 |
| **A** | **IETF SEAT WG 憲章** | `https://datatracker.ietf.org/group/seat/about/` | WebFetch。**動作確認済 2026-08-21**。2026-10-26: `charter-ietf-seat-01`（Last updated 2026-03-18）。Future work に "IKEv2 or SSH" が明記されているのを確認し、ノートを訂正 | 2026-10-26 |
| **A** | **seat@ietf.org ML** | `https://mailarchive.ietf.org/arch/browse/seat/` | WebFetch。**動作確認済 2026-09-14**。直近 40 通は "Guidance text for draft-ietf-seat-use-cases" のスレッドがほぼ占拠（9/02〜9/12）。**SSH / Secure Shell の言及は依然なし** | 2026-10-26 |
| **A** | **IETF RATS WG 文書一覧** | `https://datatracker.ietf.org/wg/rats/documents/` | WebFetch。**SSHM / SEAT と同じく「Related Internet-Drafts」欄を個別に列挙させること。** 2026-09-14 までは WG 文書 + RFC だけを見ていて Related 欄（**32 件**）を落としていた。2026-10-13 に初めて列挙させたところ**未登録 29 件**が出て、うち `draft-reddy-rats-key-binding`（→ `notes/specs/draft-reddy-rats-key-binding.md`）と `draft-ounsworth-rats-privacy-framework`、`draft-xia-rats-key-negotiation-integration` は本研究に直結していた。**Related 欄にはベンダ固有 CoRIM プロファイルと AI/GPU 系が多数混ざるので、除外条件を当てて捨てる前提で列挙させる**。**並行テーマ用に、YANG / network device 系の文書（例 `draft-ietf-rats-network-device-subscription`）は捨てずに拾う** | 2026-10-26 |
| A | IETF datatracker 検索（attestation） | `https://datatracker.ietf.org/api/v1/doc/document/?name__contains=attestation&format=json&limit=50` | API (JSON)。**動作確認済 2026-08-21**（該当 184 件）。2026-10-26: **`&type=draft` を付けると draft だけの 58 件に絞れる**。除外したものは seen に記録しないので毎回未登録に見える。版まで含めて照合し、除外条件を当て直すこと | 2026-10-26 |
| C | IETF datatracker 検索（ssh） | `https://datatracker.ietf.org/api/v1/doc/document/?name__contains=ssh&format=json&limit=100` | API (JSON)。**動作確認済 2026-09-14**。ただし**新着検出には向かない**: 返る順序が登録順で 1990 年代の期限切れ I-D が並ぶうえ、`&order_by=-time` を付けると **HTTP 400**。SSHM WG の文書一覧ページを見る方が確実。**歴史的 I-D の発掘用**と割り切ること（2026-09-14 に `draft-williams-sshv2-channel-bindings`（SSH の channel binding、問い 4 の先行事例）と `draft-saarenmaa-ssh-x509` をこれで発見）。**2026-10-26: `&type=draft&time__gte=<YYYY-MM-DD>` で更新日による絞り込みができた**（2026-09-01 以降で 6 件）。新着の検出に使える | 2026-10-26 |
| B | IETF secsh / SSH 関連 WG | `https://datatracker.ietf.org/wg/#sec` から SSH 関連を辿る | WebFetch。secsh WG は終了済みだが個人 I-D が出る | — |
| B | RFC Editor 新着 | `https://www.rfc-editor.org/search/rfc_search_detail.php?title=attestation` | WebFetch。2026-10-26: 検索結果が JavaScript で描画され、WebFetch では 0 件に見える（取得失敗） | — |
| B | TCG 仕様一覧 | `https://trustedcomputinggroup.org/resources/` | WebFetch。TPM 2.0 Library, DICE, RIM など。**並行テーマの Verifier の判定用に、PC Client Platform Firmware Profile（event log の形式）、Canonical Event Log Format、Reference Integrity Manifest を見る**（前 2 つは RFC 9684 の参照文献）。2026-10-26: 一覧ではなく個別の resource ページ（PFP、CEL、RIM IM）を直接読んだ。版は `tcg-pc-client-pfp:1.06r52` のように `id` に入れる | 2026-10-26 |
| C | FIDO Alliance 仕様 | `https://fidoalliance.org/specifications/` | WebFetch。WebAuthn の attestation statement 形式 | 2026-10-26 |
| C | W3C WebAuthn | `https://www.w3.org/TR/webauthn-3/` | WebFetch。改訂時のみ。2026-08-25 に Level 3 が W3C Recommendation になった（2026-10-26 確認） | 2026-10-26 |
| C | Confidential Computing Consortium | `https://confidentialcomputing.io/` | WebFetch | 2026-10-26 |
| B | IETF NETCONF WG 文書一覧 | `https://datatracker.ietf.org/wg/netconf/documents/` | WebFetch。**並行テーマ用。2026-10-26 追加・未巡回。** NETCONF / RESTCONF と YANG を保守する WG。文書の大半は attestation と無関係なので、**attestation / TPM / integrity / keystore に関わるものだけ**拾う。SSHM・RATS と同じく「Related Internet-Drafts」欄も一つずつ列挙させること。2026-10-26 初巡回: attestation を扱う文書はなし。Related 欄の 2 件も無関係 | 2026-10-26 |
| C | netconf@ietf.org ML | `https://mailarchive.ietf.org/arch/browse/netconf/` | WebFetch。並行テーマ用。2026-10-26 追加・未巡回。**browse 経路を使う**（ssh / seat では `/arch/search/` が 403 だった） | 2026-10-26 |
| C | IANA YANG Module Names | `https://www.iana.org/assignments/yang-parameters/yang-parameters.xhtml` | WebFetch。並行テーマ用。`ietf-tpm-remote-attestation` と `ietf-tcg-algs` の改訂（revision）を検出する。2026-10-26 追加・未巡回。2026-10-26: 最終更新 2026-10-23、両モジュールとも 2024-12-05 版のまま | 2026-10-26 |

**注（datatracker API）**: `name__contains` は文書名の部分一致なので、`slides-*`（会議スライド）や `agenda-*` も大量に混ざる（2026-08-21 確認: attestation で 184 件、うち上位は大半がスライド）。**`draft-` と `rfc` で始まる名前だけを残すこと。** スライドは I-D の動きを追う目的では不要。

**押さえておくべき既存 RFC**（初回に `notes/specs/` へ入れる）: RFC 9334 (RATS Architecture), RFC 9711 系の EAT 関連, RFC 4251–4254 (SSH), RFC 4255 (SSHFP), RFC 8709 (Ed25519 in SSH)。並行テーマ用: RFC 9684 (CHARRA YANG), RFC 6241 (NETCONF), RFC 6242 (NETCONF over SSH), RFC 8040 (RESTCONF)。番号は必ず現物で確認すること。

---

## impl — 実装・OSS 動向

| 優先 | 名前 | URL / エンドポイント | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| A | OpenSSH リリースノート | `https://www.openssh.org/releasenotes.html` | WebFetch。**`openssh.com` は `openssh.org` に 301 するので `.org` を直接叩く**。**2026-10-13 に 10.6 / 10.6p1（2026-10-06）を検出**（FIDO resident key の user-verification 保持、`ssh-add -P`、`ssh-mldsa44-ed25519`、`PubkeyOptions max-pk-ok`）。**レスポンスが遅くタイムアウトすることがある**（2026-09-14 に 1 回 60 秒超で失敗、再試行で成功） | 2026-10-26 |
| A | openssh-unix-dev ML | `https://marc.info/?l=openssh-unix-dev` | WebFetch。attestation / TPM / FIDO 関連スレのみ拾う。**2026-08-31 に失敗**（トップは月別インデックスのみでスレッド件名が出ない）。月別ページを直接叩く経路を次回試す。**2026-10-26 に初めて取得成功。月別のスレッド一覧 `https://marc.info/?l=openssh-unix-dev&r=1&b=<YYYYMM>&w=2` を使う** | 2026-10-26 |
| B | OpenSSH PROTOCOL 系ファイル | `https://raw.githubusercontent.com/openssh/openssh-portable/master/PROTOCOL{,.u2f,.agent,.sshsig,.key,.krl,.mux}` | raw を WebFetch。**動作確認済 2026-08-21**。de facto 標準の一次情報。ファイル一覧は `https://api.github.com/repos/openssh/openssh-portable/contents/` で確認。2026-10-26: `https://api.github.com/repos/openssh/openssh-portable/commits?path=<ファイル名>&since=<日時>` で変更の有無を確認できる | 2026-10-26 |
| A | ssh-tpm-agent | `https://api.github.com/repos/Foxboron/ssh-tpm-agent/releases` | GitHub API。**動作確認済 2026-09-14**（最新は依然 v0.9.0 / 2026-05-04。4 ヶ月半動きなし。**B に落としてよい**） | 2026-10-26 |
| B | go-attestation | `https://api.github.com/repos/google/go-attestation/releases` | GitHub API。**動作確認済 2026-09-14**（最新は依然 v0.6.4 / 2026-08-11） | 2026-10-26 |
| B | Keylime | `https://api.github.com/repos/keylime/keylime/releases` | GitHub API。**動作確認済 2026-08-31**（最新 v7.14.3 / 2026-07-06）。**並行テーマの Verifier の判定の参照実装としても見る。** verifier 側の変更（quote 検証、event log、policy）を拾う | 2026-10-26 |
| B | Parsec | `https://api.github.com/repos/parallaxsecond/parsec/releases` | GitHub API。**動作確認済 2026-08-31**。リリースが年 1 回程度で内容も依存更新中心。C に落としてよい | 2026-10-26 |
| C | GitHub 横断検索 | `https://api.github.com/search/repositories?q=ssh+attestation+in:name,description&sort=stars&order=desc` | GitHub API。新規プロジェクトの発見用。**`in:readme` と `sort=updated` は使わない**（下記注）。2026-08-31 は 12 件ヒットし新規 6 件。**2026-09-07・2026-09-14 とも同じ 12 件で新規ゼロ（3 回連続で飽和）**。C に降格。月 1 回で足りる。2026-10-19 も 13 件で新規 2 件はいずれも除外（学習課題・本リポジトリ自身）。2026-10-26 も同じ 13 件 | 2026-10-26 |
| C | tpm2-software | `https://api.github.com/repos/tpm2-software/tpm2-tools/releases` | GitHub API。**動作確認済 2026-08-31**（最新 5.8 / 2026-07-15）。内容は CVE 修正中心で attestation の新機能は出にくい。ただし `tpm2_checkquote` の変更は並行テーマの Verifier の判定に効くので拾う | 2026-10-26 |
| C | Linux IMA / integrity | `https://lore.kernel.org/linux-integrity/` | WebFetch。カーネル側の動き。**2026-08-31 に Access Denied で取得不可**。代替経路（`https://lore.kernel.org/linux-integrity/new.atom` 等）を次回試す。2026-10-26: `new.atom` も HTTP 403 | — |
| C | sigstore | `https://api.github.com/repos/sigstore/sigstore/releases` | GitHub API。署名検証モデルの参考。**動作確認済 2026-08-31**（最新 v1.10.9 / 2026-08-03）。内容は KMS / TUF まわりで attestation とは無関係。収穫が薄い | 2026-10-26 |
| B | CHARRA（Fraunhofer-SIT） | `https://api.github.com/repos/Fraunhofer-SIT/charra/commits?per_page=10` | GitHub API。**並行テーマ用。2026-10-26 追加・未巡回。** RATS の Reference Interaction Models の challenge-response モデルを TPM 2.0 で実装した PoC（リポジトリの description による）。Verifier の判定の実装例として、quote 検証まわりのコミットを拾う。2026-10-26 時点で archived ではなく、最終 push は 2026-10-01 | 2026-10-26 |
| C | netopeer2 | `https://api.github.com/repos/CESNET/netopeer2/releases` | GitHub API。並行テーマ用。2026-10-26 追加・未巡回（同日時点の最新は 2.8.21 / 2026-10-14）。リリースは依存更新とバグ修正が中心なので、RPC 処理と NACM に関わる変更だけ拾う | 2026-10-26 |
| C | sysrepo | `https://api.github.com/repos/sysrepo/sysrepo/releases` | GitHub API。並行テーマ用。2026-10-26 追加・未巡回（同日時点の最新は v5.2.27 / 2026-10-14）。plugin API（`sysrepo-plugind`）に関わる変更だけ拾う | 2026-10-26 |
| C | GitHub 横断検索（並行テーマ） | `https://api.github.com/search/repositories?q=netconf+attestation+in:name,description&sort=stars&order=desc` / `https://api.github.com/search/repositories?q=yang+tpm+attestation+in:name,description&sort=stars&order=desc` | GitHub API。並行テーマ用。2026-10-26 追加・未巡回。主テーマの横断検索と同じく `in:readme` と `sort=updated` は使わない。2026-10-26 初巡回: netconf は 0 件、yang+tpm は `ietf-rats-wg/basic-yang-module` の 1 件 | 2026-10-26 |

**GitHub API の注意**: 未認証だと 60 req/hour。1 回の `/collect` で叩くのは上記程度に留める。403 が返ったら inbox に `レート制限で取得失敗` と記録して次に進む。

**注（横断検索のクエリ）**: 2026-08-21 に `q=ssh+attestation+in:name,description,readme&sort=updated` を試したところ、**total 3,851 件・上位は「今日 push された無関係リポジトリ」で埋まり、実質使い物にならなかった**。原因は (1) `in:readme` が「SBOM の sigstore attestation」等を大量に拾う、(2) `sort=updated` が関連度を完全に無視する、の 2 点。**`in:name,description` に絞り、`sort=stars` を使うこと。** なお 2026-08-21 に発見された有用な実装 2 件（`ssh-tpm-ca-authority`, `HardwareProtectedSsh`）は、いずれも GitHub 検索ではなく**汎用 Web 検索**経由で見つかった。実装の発見は Web 検索の方が当たりが良い。

2026-08-31 も同じ傾向。`in:name,description` + `sort=stars` の横断検索は 12 件と扱える量に収まり `ssh-sk-verify` 等を拾えたが、この日の最大の収穫だった `smallstep/ssh-attest-proxy` は**リポジトリに description が無いため GitHub 検索には引っかからず、汎用 Web 検索でしか出てこなかった**。impl は GitHub API と Web 検索を必ず併用すること。

---

## industry — 製品・業界動向

| 優先 | 名前 | URL | 取得方法 | 最終確認日 |
|---|---|---|---|---|
| B | Teleport ブログ | `https://goteleport.com/blog/` | WebFetch。Device Trust / Machine ID が近い。**タグページ `https://goteleport.com/blog/tags/device-trust/` は 2026-09-07 に 404**。**2026-09-14 はトップ一覧を取得できたが記事に公開日が出ず、月での絞り込みができなかった**（タイトルにも device trust / attestation 系はなし）。日付付きの一覧（RSS `https://goteleport.com/blog/rss.xml` 等）を次回試すこと。**2026-10-26: RSS `https://goteleport.com/blog/rss.xml` で pubDate 付きの一覧が取れた。以後はこちらを使う** | 2026-10-26 |
| B | Tailscale ブログ | `https://tailscale.com/blog` | WebFetch。Tailscale SSH, device posture。**動作確認済 2026-09-14**（8〜9 月分は Tailcat / K8s Operator 1.102 / DNS filtering 等で attestation の技術的中身なし） | 2026-10-26 |
| C | HashiCorp ブログ | `https://www.hashicorp.com/blog` | WebFetch。Boundary 関連のみ | 2026-10-26 |
| C | Google Cloud Confidential Computing | `https://cloud.google.com/blog/products/identity-security` | WebFetch。2026-10-26: 記事一覧に日付が出ない | 2026-10-26 |
| C | AWS Nitro Enclaves | `https://aws.amazon.com/blogs/security/` | WebFetch。attestation document 関連 | 2026-10-26 |
| C | Azure Attestation | `https://azure.microsoft.com/en-us/blog/` | WebFetch | 2026-10-26 |
| C | Cloudflare ブログ | `https://blog.cloudflare.com/` | WebFetch。Access / device posture | 2026-10-26 |

**注**: `industry` は最もノイズが多い。`docs/scope.md` の「ベンダのマーケティング記事」除外条件を厳しく当てること。原則 `relevance: medium` 以下で、**新プロトコル・新方式の初出だけ** `high` にする。

---

## 取得のコツ

- **API があるものは API を使う**（arXiv, datatracker, GitHub）。HTML スクレイプは構造変更で壊れる。
- 取得に失敗したソースは**黙って飛ばさず**、inbox に `- [取得失敗] <名前> — <理由>` として記録する。次回に持ち越せる。
- 1 回の `/collect` で全部を舐めようとしない。**優先 A を確実に、B を可能な範囲で、C は月 1 回**。
- 会議の採録リストは巨大なので、ページ全体を要約せず**キーワードに一致するタイトルだけ**を抜く。
