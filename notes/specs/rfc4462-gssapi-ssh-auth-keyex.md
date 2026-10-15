---
id: "rfc:4462"
title: "Generic Security Service Application Program Interface (GSS-API) Authentication and Key Exchange for the Secure Shell (SSH) Protocol"
body: "IETF"
status: "Proposed Standard"
year: 2006
url: "https://www.rfc-editor.org/info/rfc4462"
type: spec
tags: [ssh, gssapi, kerberos, userauth, gssapi-with-mic, gssapi-keyex, session-identifier, mic, relay-attack, null-host-key, message-numbers, precedent]
relevance: high
added: 2026-10-13
---

> **SSH に新しい認証方式を追加した唯一の本格的な先例。** 研究テーマ（attestation をクライアント認証に拡張し、server challenge / client response で行う）の設計をそのまま載せられる型がここにある。
> 中核 5 本の地図は [[ssh-core-rfcs]]。本ノートは RFC 4462 単体の精読。

## 何を規定しているか

GSS-API（実質 Kerberos V5）を SSH に統合する Standards Track RFC（2006-05）。著者は J. Hutzelman (CMU), J. Salowey (Cisco Systems), J. Galbraith (Van Dyke Technologies), V. Welch (U Chicago / ANL)。

定義しているものは 4 つ:

| 対象 | 名前 | 使うメッセージ番号 |
|---|---|---|
| 鍵交換方式 | `gss-group1-sha1-*` / `gss-group14-sha1-*` / `gss-gex-sha1-*` | **30–49**（`SSH_MSG_KEXGSS_INIT`=30 ほか 7 個） |
| ユーザ認証方式 | **`gssapi-with-mic`** | **60–79**（60, 61, 63, 64, 65, 66） |
| ユーザ認証方式 | **`gssapi-keyex`**（KEX で確立した文脈を認証層で消費） | 追加メッセージなし（`SSH_MSG_USERAUTH_REQUEST` 1 通） |
| ホスト鍵アルゴリズム | **`null`**（鍵材料を持たない） | — |

## 本研究に効く定義・要件

### §3 `gssapi-with-mic` — server challenge / client response の既製の型

フローは次のとおり（§3.1–3.7）:

```
C → S: SSH_MSG_USERAUTH_REQUEST ("gssapi-with-mic", 対応する mechanism OID の列)
S → C: SSH_MSG_USERAUTH_GSSAPI_RESPONSE (60)   ← 選んだ mechanism OID
C ⇄ S: SSH_MSG_USERAUTH_GSSAPI_TOKEN (61) を必要な回数往復
C → S: SSH_MSG_USERAUTH_GSSAPI_MIC (66)        ← クライアントが最後に MIC を送る
S → C: SSH_MSG_USERAUTH_SUCCESS / FAILURE (partial success 可)
```

**本研究にとっての意味が 3 つある。**

#### (1) クライアントが 60–79 番のメッセージを送る先例として決定的

`SSH_MSG_USERAUTH_GSSAPI_MIC`（66）と `SSH_MSG_USERAUTH_GSSAPI_EXCHANGE_COMPLETE`（63）は**クライアントが送る**。`SSH_MSG_USERAUTH_GSSAPI_TOKEN`（61）は双方向。

> The numbers 60-79 are specific to user authentication and may be redefined by other user auth methods. — §6

これは [[rfc4252-ssh-authentication-protocol]] §6 の括弧書き「These messages are only sent by the server (client sends only SSH_MSG_USERAUTH_REQUEST messages)」と食い違う。[[rfc4256-keyboard-interactive]] でも同じ食い違いを見つけていたが、**RFC 4462 という 2 つめの Standards Track の例が出たことで、4252 §6 の括弧書きは当時の方式群の記述であって規範ではない、と安心して扱える。** 本研究で「サーバーが challenge を 60–79 番で送り、クライアントが Evidence を 60–79 番で返す」設計を取ることに、仕様上の障害はない。

#### (2) §3.5 の MIC がセッション束縛の正解の形を示している

MIC の計算対象は次の連結である:

```
string    session identifier
byte      SSH_MSG_USERAUTH_REQUEST
string    user name
string    service
string    "gssapi-with-mic"
```

**[[rfc4252-ssh-authentication-protocol]] §7 の `publickey` 認証の署名対象と同じ構造**（先頭が session identifier、以下メッセージの文脈）。しかも**なぜそうするのかが明記されている**:

> In some cases, it is possible to obtain improved security by allowing access only if the client sends a valid message integrity code (MIC) binding the GSS-API context to the keys used for encryption and integrity protection of the SSH session. With this extra level of protection, a "man-in-the-middle" attacker who has convinced a client of his authenticity cannot then relay user authentication messages between the real client and server, thus gaining access to the real server. — §3.5

**これは [[2026-sardar-identity-crisis-attested-tls]] が attested TLS で指摘した diversion / relay 攻撃と同じ構造の攻撃である。** SSH は 2006 年の時点で、GSS-API について「認証の成果物を session identifier に束縛する」という形でこれを潰していた。

さらに、束縛が使えない場合の扱いまで決めてある（§3.6）。per-message integrity protection が使えないときはクライアントは MIC ではなく `SSH_MSG_USERAUTH_GSSAPI_EXCHANGE_COMPLETE`（63）を送る。そして:

> It is a site policy decision for the server whether or not to permit authentication using GSS-API mechanisms and/or contexts that do not support per-message integrity protection. The server MAY fail the otherwise valid gssapi-with-mic authentication if per-message integrity protection is not supported. — §3.6

**束縛の有無をサーバーのポリシーで選ばせる**という設計。段階的導入（問い 2）の型としてそのまま使える。

#### (3) §7.2 で GSS-API のチャネル束縛を「使うな」としている

> This document recommends that channel bindings SHOULD NOT be specified in the calls during context establishment. This document does not specify any standard data to be used as channel bindings, and the use of network addresses as channel bindings may break SSH in environments where it is most useful. — §7.2

つまり **GSS-API 層のチャネル束縛機構は採らず、SSH 層の session identifier への束縛（§3.5）を選んだ**。下位機構の汎用束縛より、SSH 固有の session identifier を使うほうが実際的だという判断が先例として存在する。

### §4 `gssapi-keyex` — 鍵交換で作った文脈を認証層で使う

鍵交換が GSS-API ベースの方式で行われた場合に限り使える認証方式。メッセージは 1 通だけ:

```
byte      SSH_MSG_USERAUTH_REQUEST
string    user name
string    service
string    "gssapi-keyex"
string    MIC          ← session identifier ‖ ... を対象とした MIC
```

制約が 2 つ明記されている:

- 初回鍵交換で確立した文脈のみ使える。**`Any context established during key exchange for the purpose of rekeying MUST NOT be used with this method.`**（§4）
- 鍵交換が GSS-API 方式でなかったのにこの方式を要求されたら、サーバーは `SSH_MSG_USERAUTH_FAILURE` を返さなければならない (MUST)

サーバーは、初回鍵交換が GSS-API 方式で、かつユーザの identity 情報が得られる場合に、この方式を `SSH_MSG_USERAUTH_FAILURE` の継続可能リストに含めるべき (SHOULD)。

### §5 `null` ホスト鍵アルゴリズム

鍵材料も署名も暗号も持たないホスト鍵アルゴリズム。公開鍵演算を要さない鍵交換方式（＝ §2 の GSS-API 方式）とだけ使える。存在理由は実務的で、**「サーバーは何らかのホスト鍵アルゴリズムを広告する必要があるので、その枠を埋めるため」**。

> Any implementation supporting at least one key exchange method that conforms to Section 2 MUST also support the "null" host key algorithm. Servers MUST NOT advertise the "null" host key algorithm unless it is the only algorithm advertised. — §5

### §2.1 鍵交換方式の構成

exchange hash の材料は素の DH（[[rfc4253-ssh-transport-layer]] §8）と同じ `V_C / V_S / I_C / I_S / e / f / K` の系列を踏む。相互認証を要求するため `mutual_req_flag` を true に、per-message integrity を要求するため `integ_req_flag` を true にすることが MUST。

注目すべき点: **`gssapi-keyex` を使う意図がないなら `anon_req_flag` を true にすべき (SHOULD)** とある。鍵交換はホストの認証しかしないので、クライアントの identity を隠せる。**プライバシーに配慮した既定値を仕様が用意している**例。

## 拡張点・自由度

- 認証方式の方式固有メッセージ（60–79）の割り当てと向きは方式の定義者が自由に決められる（§6 が明言）
- 鍵交換方式の 30–49 も同様
- 束縛を要求するか否かをサーバーのポリシーに委ねられる（§3.6）
- §2.6 "Other GSS-API Key Exchange Methods" が、同じ枠で別の方式を定義する道を開けている

## 他仕様との関係

- 土台: [[rfc4252-ssh-authentication-protocol]]（認証方式の枠組み）、[[rfc4253-ssh-transport-layer]]（鍵交換、session identifier）、[[rfc4251-ssh-architecture]]
- 番号と名前: [[rfc4250-ssh-assigned-numbers]]。IANA の Authentication Method Names には `gssapi-with-mic` / `gssapi-keyex` / `gssapi` / `external-keyx` が登録されている（2026-09-08 時点、→ [[iana-ssh-registry-and-extension-points]]）
- 更新: RFC 9142（KEX の推奨更新）が 4462 を更新している（→ [[ssh-core-rfcs]]）
- 本研究の関連: [[rfc4256-keyboard-interactive]]（もう 1 つの認証方式追加例。ただし汎用プロンプト方式で束縛を持たない）

## 引用すべき箇所

> With this extra level of protection, a "man-in-the-middle" attacker who has convinced a client of his authenticity cannot then relay user authentication messages between the real client and server, thus gaining access to the real server.
> — RFC 4462, §3.5

> The contents of the MIC field are obtained by calling GSS_GetMIC() over the following, using the GSS-API context that was just established: string session identifier, byte SSH_MSG_USERAUTH_REQUEST, string user name, string service, string "gssapi-with-mic"
> — RFC 4462, §3.5

> The numbers 60-79 are specific to user authentication and may be redefined by other user auth methods.
> — RFC 4462, §6

> This document recommends that channel bindings SHOULD NOT be specified in the calls during context establishment.
> — RFC 4462, §7.2

> Any context established during key exchange for the purpose of rekeying MUST NOT be used with this method.
> — RFC 4462, §4

## 自研究との関係

（※ここは解釈）

**この RFC は本研究の「設計の型」になる。** 研究テーマが求める「server からの challenge、client からの response、client の完全性の保証」を SSH に載せるとき、ゼロから考える必要はなく、`gssapi-with-mic` の構造を attestation に置き換えればよい:

| `gssapi-with-mic` | 本研究の対応物 |
|---|---|
| クライアントが対応 mechanism OID の列を送る | クライアントが対応する attestation 形式・ハッシュアルゴリズム・PCR バンクの列を送る |
| サーバーが選んだ OID を 60 番で返す | **サーバーが challenge（nonce）と Claim Selection を 60 番台で返す** |
| トークンを 61 番で往復 | クライアントが Evidence（TPM Quote + AK 証明 + 必要ならイベントログ）を返す。サイズが大きければ分割が要る |
| クライアントが session identifier を含む MIC を 66 番で送る | **Evidence を session identifier に束縛する**（TPM の `qualifyingData` に `challenge ‖ session identifier` の正規化値を入れる、→ [[tcg-tpm2-library-v185]]） |
| 束縛を要求するかはサーバーのポリシー（§3.6） | attestation を要求するかはサーバーのポリシー。`partial success` で `publickey` の後段に置ける |

**§3.5 の存在が、本研究の freshness 設計の論拠を一段強くする。** [[rfc4253-ssh-transport-layer]] のノートでは「H や session identifier を Handle として使えるか論証が要る」と書いた。RFC 4462 §3.5 は **SSH における先例として、認証の成果物を session identifier に束縛することで relay を防ぐという論法を仕様レベルで確立している。** 本研究は「新しいことをする」のではなく「SSH が GSS-API について既に採った束縛の論法を、attestation Evidence に適用する」と言える。これは査読でも IETF でも通りやすい。

**ただし差分も明確にしておく必要がある。** GSS-API の MIC は「確立した文脈で生成した MAC」であり、attestation の Evidence は「TPM が内部で署名した構造体」である。TPM の署名対象は `TPMS_ATTEST` の中身に限られ、任意のバイト列を MIC のように自由に対象にできない。入れられるのは `qualifyingData`（上限は 2 + TPM の最長ダイジェスト長、→ [[tcg-tpm2-library-v185]]）だけ。**したがって「session identifier を含む長い連結に署名する」という 4462 の形はそのままは踏めず、連結をハッシュして `qualifyingData` に入れる形に変える必要がある。** ここが設計上の実質的な差分であり、論文で書くべき箇所。

**`gssapi-keyex` の制約も効く。** 「rekey で確立した文脈は使ってはいけない」という規定は、**初回鍵交換とその後の rekey を区別する必要があることの先例**。本研究で rekey に再 attestation を乗せる案（[[rfc4253-ssh-transport-layer]] §9）を採るなら、初回の Evidence と再 attestation の Evidence を仕様上どう区別するかを決めねばならない。

**`null` ホスト鍵アルゴリズムは「交渉の枠を埋めるための擬似アルゴリズム名」の先例。** RFC 8308 の `ext-info-c` / `ext-info-s`（[[rfc8308-ssh-extension-negotiation]]）と同じ手口が、2006 年の時点で既にあったことになる。本研究で attestation 対応を KEXINIT で表明する必要が出たとき、2 つの先例を引ける。

**§2.1 の `anon_req_flag` の扱いはプライバシー設計の参考になる。** 「鍵交換ではホストしか認証しないので、クライアントの identity を隠せる場合は隠す」という既定。クライアント端末を Attester にする本研究のプライバシー問題（[[openssh-protocol-extensions]] に記録）に対し、「必要な場面だけ identity を出す」という設計態度の先例として引ける。

## 未解決・気になる点

- **§3.4 GSS-API Session、§3.7–3.9（Completion / Error Status / Error Token）が未読。** 多ラウンドのやりとりでエラーをどう返すかは、attestation の検証失敗をどう伝えるかの設計に直結する。**エラー処理は仕様の実用性を決める部分なので、次に読むならここ**
- §2.1 の鍵交換手順の全体（GSS トークンと DH の絡み方、exchange hash の正確な定義）が未精読
- OpenSSH は `gssapi-with-mic` を実装しているが `gssapi-keyex` は本体に入っていない（Debian 等のパッチで提供されている）はず。**この「採択されなかった方式」の事実関係を確認する価値がある**——本研究が KEX 案ではなく認証方式案を採る根拠として使える可能性
- RFC 9142 が 4462 の何を更新したか（[[ssh-core-rfcs]] からの積み残し）
- `external-keyx` という認証方式名が IANA に登録されているが、どの RFC が定義したか未確認（4462 の一部か別文書か）
