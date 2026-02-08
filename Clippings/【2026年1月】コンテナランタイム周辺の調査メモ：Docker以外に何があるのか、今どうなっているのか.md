---
title: "【2026年1月】コンテナランタイム周辺の調査メモ：Docker以外に何があるのか、今どうなっているのか"
source: "https://zenn.dev/nossa/articles/a6f5b342ad83f0"
author:
  - "[[Zenn]]"
published: 2026-01-04
created: 2026-01-06
description:
tags:
  - "WebClip"
  - "Docker"
  - "Kubernetes"
  - "Linux"
  - "Container Runtime"
  - "Podman"
  - "containerd"
  - "CRI-O"
  - "gVisor"
  - "Kata Containers"
  - "WebAssembly"
  - "eBPF"
---
# ✅️ Abstact

## コンテナランタイム調査メモ（2026年1月）

### 概要
コンテナランタイムのレイヤー構造、主要なOCI Runtime、CRI Runtime、コンテナエンジン、イメージビルドツールについて調査・整理。

### コンテナ技術のレイヤー構造
- **ユーザー向け**: Docker, Podman など
- **高レベルランタイム (CRI)**: Kubernetes連携 (containerd, CRI-O)
- **低レベルランタイム (OCI)**: コンテナ実行 (runc, crun, gVisor, Kata)
- **基盤**: Linuxカーネル (namespaces, cgroups)

### 低レベルランタイム (OCI Runtime)
- **標準**: runc (リファレンス実装)
- **高パフォーマンス**: crun, youki
- **高セキュリティ**: gVisor (ユーザー空間カーネル), Kata Containers (軽量VM)
- **選択基準**: 用途（速度、セキュリティ、分離レベル）に応じて選択

### 高レベルランタイム (CRI Runtime)
- **containerd**: CNCFプロジェクト、広く採用
- **CRI-O**: Kubernetes専用、軽量
- **RuntimeClass**: Pod単位でランタイムを選択可能

### コンテナエンジン / CLI
- **Docker**: エコシステム充実、有料化の動き
- **Podman**: デーモンレス、Rootless、Pod機能、systemd連携 (Quadlet)
- **nerdctl**: containerd用CLI、Compose/Wasm対応
- **macOS向け**: Colima, OrbStack, Rancher Desktop
- **LXC/LXD (Incus)**: システムコンテナ (OS起動)

### イメージビルドツール
- **BuildKit**: Docker標準、高機能
- **Buildah**: Podman付属、デーモン不要
- **Kaniko**: K8s向け、特権不要
- **ko**: Go言語専用
- **Skopeo**: イメージ転送・検査

### 近年の流れ
- **標準化**: OCI/CRIによりコンポーネント交換容易
- **棲み分け**: 開発(Docker), 本番(containerd), セキュリティ(Podman)
- **セキュリティ強化**: Rootless → gVisor → Kata → Confidential Computing
- **次世代**: WebAssembly (Wasm) の台頭
- **可観測性**: eBPF の普及

### 今後
- **トレンド**: マルチランタイム、Confidential Computing, Wasm, サプライチェーンセキュリティ
- **用途別**: 開発(Docker/Podman), 本番K8s(containerd), エッジ(Wasm), 機密処理(Kata+Confidential)

### まとめ
- コンテナ技術は標準化・高機能化が進展
- 用途に応じて最適なランタイム・ツールの選択が重要
- WasmやConfidential Computingが将来の選択肢として注目

---

# 🗒️ Summary

```markdown
<a href=\\"https://zenn.dev/nossa\\"><img alt=\\"のさ\\" src=\\"https://lh3.googleusercontent.com/a-/AOh14GixT6nDD7c4euj57-Hfjct1YuHoMUSccfNRRBKq=s96-c\\">のさ</a>目次3113<a href=\\"https://twitter.com/intent/tweet?url=https://zenn.dev/nossa/articles/a6f5b342ad83f0&text=%E3%80%902026%E5%B9%B41%E6%9C%88%E3%80%91%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E5%91%A8%E8%BE%BA%E3%81%AE%E8%AA%BF%E6%9F%BB%E3%83%A1%E3%83%A2%EF%BC%9ADocker%E4%BB%A5%E5%A4%96%E3%81%AB%E4%BD%95%E3%81%8C%E3%81%82%E3%82%8B%E3%81%AE%E3%81%8B%E3%80%81%E4%BB%8A%E3%81%A9%E3%81%86%E3%81%AA%E3%81%A3%E3%81%A6%E3%81%84%E3%82%8B%E3%81%AE%E3%81%8B%EF%BD%9C%E3%81%AE%E3%81%95&hashtags=zenn\\"></a><a href=\\"http://www.facebook.com/sharer.php?u=https://zenn.dev/nossa/articles/a6f5b342ad83f0\\" id=\\"gtm-article-left-facebook\\"></a><a href=\\"https://b.hatena.ne.jp/add?mode=confirm&url=https://zenn.dev/nossa/articles/a6f5b342ad83f0&title=%E3%80%902026%E5%B9%B41%E6%9C%88%E3%80%91%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E5%91%A8%E8%BE%BA%E3%81%AE%E8%AA%BF%E6%9F%BB%E3%83%A1%E3%83%A2%EF%BC%9ADocker%E4%BB%A5%E5%A4%96%E3%81%AB%E4%BD%95%E3%81%8C%E3%81%82%E3%82%8B%E3%81%AE%E3%81%8B%E3%80%81%E4%BB%8A%E3%81%A9%E3%81%86%E3%81%AA%E3%81%A3%E3%81%A6%E3%81%84%E3%82%8B%E3%81%AE%E3%81%8B%EF%BD%9C%E3%81%AE%E3%81%95\\" id=\\"gtm-article-left-hatena-bookmark\\"></a><a href=\\"https://zenn.dev/topics/docker\\"><img src=\\"https://storage.googleapis.com/zenn-user-upload/topics/75b80a5922.png\\">Docker</a><a href=\\"https://zenn.dev/topics/linux\\"><img src=\\"https://storage.googleapis.com/zenn-user-upload/topics/860a9eb1e4.png\\">Linux</a><a href=\\"https://zenn.dev/topics/kubernetes\\"><img src=\\"https://storage.googleapis.com/zenn-user-upload/topics/0b101ae2f2.png\\">Kubernetes</a><a href=\\"https://zenn.dev/topics/webassembly\\"><img src=\\"https://storage.googleapis.com/zenn-user-upload/topics/3de7a9f43a.png\\">WebAssembly</a><a href=\\"https://zenn.dev/topics/container\\"><img src=\\"https://storage.googleapis.com/zenn-user-upload/topics/3de7a9f43a.png\\">container</a><a href=\\"https://zenn.dev/tech-or-idea\\"><img src=\\"https://static.zenn.studio/images/drawing/tech-icon.svg\\">tech</a>!

<p>可能な限り公式ドキュメント等で裏取りを行っていますが、この記事は個人的な調査メモであり、内容の正確性を保証するものではありません。
技術選定や本番環境への導入に際しては、必ず各プロジェクトの公式ドキュメントをご確認ください。</p>

<h2 id=\\"%E3%81%93%E3%81%AE%E8%A8%98%E4%BA%8B%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\">
<a href=\\"#%E3%81%93%E3%81%AE%E8%A8%98%E4%BA%8B%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\"></a> この記事について</h2>
<p>コンテナランタイムについて調べ直したのでメモを残します。</p>
<p>「コンテナランタイム」という言葉は文脈によって指すものが異なります。低レベルのOCI Runtime、高レベルのCRI Runtime、Docker/Podmanのようなエンジン全体。このあたりを整理しつつ、2026年1月時点の状況をまとめました。</p>

<h2 id=\\"%E7%9B%AE%E6%AC%A1\\">
<a href=\\"#%E7%9B%AE%E6%AC%A1\\"></a> 目次</h2>
<ol>
<li><a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E6%8A%80%E8%A1%93%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E6%A7%8B%E9%80%A0\\">コンテナ技術のレイヤー構造</a></li>
<li><a href=\\"#%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0oci-runtime\\">低レベルランタイム（OCI Runtime）</a></li>
<li><a href=\\"#%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0cri-runtime\\">高レベルランタイム（CRI Runtime）</a></li>
<li><a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3--cli\\">コンテナエンジン / CLI</a></li>
<li><a href=\\"#%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%83%93%E3%83%AB%E3%83%89%E3%83%84%E3%83%BC%E3%83%AB\\">イメージビルドツール</a></li>
<li><a href=\\"#%E3%81%93%E3%81%93%E6%95%B0%E5%B9%B4%E3%81%AE%E6%B5%81%E3%82%8C\\">ここ数年の流れ</a></li>
<li><a href=\\"#%E4%BB%8A%E5%BE%8C%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\">今後について</a></li>
</ol>

<h2 id=\\"%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E6%8A%80%E8%A1%93%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E6%A7%8B%E9%80%A0\\">
<a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E6%8A%80%E8%A1%93%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E6%A7%8B%E9%80%A0\\"></a> コンテナ技術のレイヤー構造</h2>
<p>コンテナ技術は大きく3層に分かれている。</p>
<h3 id=\\"%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC%E5%90%91%E3%81%91%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC\\">
<a href=\\"#%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC%E5%90%91%E3%81%91%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC\\"></a> ユーザー向けレイヤー</h3>
<p>ユーザーが直接操作するツール群。docker run や podman build などのコマンドを提供する。</p>
<h3 id=\\"%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89\\">
<a href=\\"#%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89\\"></a> 高レベルランタイム（CRI Runtime）</h3>
<p>CRI（Container Runtime Interface）はKubernetesがコンテナランタイムと通信するための標準インターフェース。containerdやCRI-Oがこれを実装している。</p>
<h3 id=\\"%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89\\">
<a href=\\"#%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89\\"></a> 低レベルランタイム（OCI Runtime）</h3>
<p>OCI（Open Container Initiative）はコンテナの標準仕様を策定する団体。OCI Runtime Specに準拠したランタイムが実際にコンテナを起動する。</p>
<h3 id=\\"linux%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB\\">
<a href=\\"#linux%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB\\"></a> Linuxカーネル</h3>
<ul>
<li>
<strong>namespaces</strong>: プロセス、ネットワーク、ファイルシステムなどを隔離するLinuxカーネルの機能</li>
<li>
<strong>cgroups</strong>: CPU、メモリなどのリソース使用量を制限するLinuxカーネルの機能</li>
<li>
<strong>seccomp</strong>: システムコール（カーネルへの命令）を制限するセキュリティ機構</li>
<li>
<strong>SELinux</strong>: アクセス制御を強制するセキュリティモジュール</li>
</ul>
<h3 id=\\"%E5%90%84%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%81%AE%E5%BD%B9%E5%89%B2\\">
<a href=\\"#%E5%90%84%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%81%AE%E5%BD%B9%E5%89%B2\\"></a> 各レイヤーの役割</h3>
<table>

<tr>
<th>レイヤー</th>
<th>役割</th>
<th>具体例</th>
</tr>

<tr>
<td><strong>コンテナエンジン / CLI</strong></td>
<td>ユーザーインターフェース、イメージのpull/push/build、ネットワーク設定、ボリューム管理</td>
<td>Docker, Podman, nerdctl</td>
</tr>
<tr>
<td><strong>高レベルランタイム (CRI)</strong></td>
<td>コンテナのライフサイクル管理、イメージ取得、Kubernetes連携</td>
<td>containerd, CRI-O</td>
</tr>
<tr>
<td><strong>低レベルランタイム (OCI)</strong></td>
<td>コンテナの起動・停止、namespace/cgroups操作</td>
<td>runc, crun, gVisor, Kata</td>
</tr>

</table>

<h2 id=\\"%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89-1\\">
<a href=\\"#%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89-1\\"></a> 低レベルランタイム（OCI Runtime）</h2>
<h3 id=\\"oci%E6%A8%99%E6%BA%96\\">
<a href=\\"#oci%E6%A8%99%E6%BA%96\\"></a> OCI標準</h3>
<p>2015年にDocker社がOpen Container Initiative (OCI) を設立。コンテナ技術の標準化が目的。</p>
<ul>
<li>
<strong>OCI Runtime Specification</strong>: コンテナの起動・停止・管理の仕様</li>
<li>
<strong>OCI Image Specification</strong>: コンテナイメージのフォーマット仕様</li>
</ul>
<p>これにより、異なるランタイム間でもイメージやコンテナの互換性が保たれる。</p>
<h3 id=\\"%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E6%A8%99%E6%BA%96%E5%AE%9F%E8%A3%85\\">
<a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E6%A8%99%E6%BA%96%E5%AE%9F%E8%A3%85\\"></a> 主要なOCI Runtime：標準実装</h3>
<h4 id=\\"runc\\">
<a href=\\"#runc\\"></a> runc</h4>
<ul>
<li>OCIのリファレンス実装（公式の参照実装）</li>
<li>多くの環境でデフォルトとして使われる代表的なOCI Runtime</li>
<li>Go言語で記述</li>
</ul>
<h3 id=\\"%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E9%87%8D%E8%A6%96\\">
<a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E9%87%8D%E8%A6%96\\"></a> 主要なOCI Runtime：パフォーマンス重視</h3>
<h4 id=\\"crun\\">
<a href=\\"#crun\\"></a> crun</h4>
<ul>
<li>Red Hat開発、C言語実装</li>
<li>runcより起動が速い傾向があり、リソース効率の観点で選ばれることがある</li>
</ul>
<h4 id=\\"youki\\">
<a href=\\"#youki\\"></a> youki</h4>
<ul>
<li>Rust製、日本人開発者が主導</li>
<li>メモリ安全性重視（Rustの特性を活かしてメモリ関連のバグを防ぐ）</li>
<li>Podmanで利用可能</li>
<li>実験段階</li>
</ul>
<h3 id=\\"%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E9%87%8D%E8%A6%96-1\\">
<a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E9%87%8D%E8%A6%96-1\\"></a> 主要なOCI Runtime：パフォーマンス重視</h3>
<h4 id=\\"crun-1\\">
<a href=\\"#crun-1\\"></a> crun</h4>
<ul>
<li>Red Hat開発、C言語実装</li>
<li>runcより起動が速い傾向があり、リソース効率の観点で選ばれることがある</li>
</ul>
<h4 id=\\"youki-1\\">
<a href=\\"#youki-1\\"></a> youki</h4>
<ul>
<li>Rust製、日本人開発者が主導</li>
<li>メモリ安全性重視（Rustの特性を活かしてメモリ関連のバグを防ぐ）</li>
<li>Podmanで利用可能</li>
<li>実験段階</li>
</ul>
<h3 id=\\"%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E9%87%8D%E8%A6%96\\">
<a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E9%87%8D%E8%A6%96\\"></a> 主要なOCI Runtime：セキュリティ重視</h3>
<h4 id=\\"gvisor-(runsc)\\">
<a href=\\"#gvisor-(runsc)\\"></a> gVisor (runsc)</h4>
<ul>
<li>Google開発</li>
<li>ユーザー空間でLinuxカーネルを再実装し、システムコール（アプリがカーネルに送る命令）を傍受・処理</li>
<li>カーネル脆弱性の影響を受けにくい</li>
<li>一部システムコール未実装など互換性の制約があり、ワークロードによってはオーバーヘッドが出る</li>
<li>Google Cloud Run、GKE Sandboxで使用されている</li>
</ul>
<p><strong>gVisorのアーキテクチャ</strong></p>
<ul>
<li>
<strong>Sentry</strong>: ユーザー空間で動作する擬似カーネル。アプリからのシステムコールを受け取り、大部分を自前で処理する</li>
<li>
<strong>Gofer</strong>: ファイルシステムへのアクセスを代理で行うプロセス</li>
</ul>
<h4 id=\\"kata-containers\\">
<a href=\\"#kata-containers\\"></a> Kata Containers</h4>
<ul>
<li>各コンテナが独自カーネルを持つ軽量VM（microVM）として動作</li>
<li>ハードウェアレベルの隔離（VMと同等のセキュリティ）</li>
<li>強い分離が必要なワークロードでの選択肢になる</li>
<li>AWS Firecracker（Lambda基盤）も同様の思想</li>
<li>Confidential Computing（後述）と組み合わせる構成もある</li>
</ul>
<p><strong>通常のコンテナとKata Containersの違い</strong></p>
<p>通常のコンテナ（runc）:</p>
<p>Kata Containers:</p>
<p>通常のコンテナは1つのカーネルを共有するが、Kata Containersは各コンテナが独自のカーネルを持つ。</p>
<h3 id=\\"%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96\\">
<a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96\\"></a> 選択基準</h3>
<table>

<tr>
<th>要件</th>
<th>選択肢</th>
</tr>

<tr>
<td>特になし</td>
<td>runc</td>
</tr>
<tr>
<td>起動速度・リソース効率</td>
<td>crun</td>
</tr>
<tr>
<td>マルチテナント・セキュリティ強化</td>
<td>gVisor</td>
</tr>
<tr>
<td>最高レベルの分離</td>
<td>Kata Containers</td>
</tr>
<tr>
<td>Rust・特定のエコシステム</td>
<td>youki</td>
</tr>

</table>

<h2 id=\\"%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89-1\\">
<a href=\\"#%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89-1\\"></a> 高レベルランタイム（CRI Runtime）</h2>
<h3 id=\\"kubernetes%E3%81%A8cri%E3%81%AE%E7%B5%8C%E7%B7%AF\\">
<a href=\\"#kubernetes%E3%81%A8cri%E3%81%AE%E7%B5%8C%E7%B7%AF\\"></a> KubernetesとCRIの経緯</h3>
<p>Kubernetesは当初Dockerに直接依存していたが、柔軟性のためCRI（Container Runtime Interface）を導入した。</p>
<p><strong>dockershim</strong>: KubernetesがDockerと通信するためのアダプター。CRI導入後は不要になり削除された。</p>
<h3 id=\\"dockershim%E5%89%8A%E9%99%A4%E5%89%8D%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\">
<a href=\\"#dockershim%E5%89%8A%E9%99%A4%E5%89%8D%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\"></a> dockershim削除前のアーキテクチャ</h3>
<p>kubelet（Kubernetesのノードエージェント）がdockershimを経由してDockerを呼び出し、さらにcontainerdを経由するという冗長な構成だった。</p>
<h3 id=\\"dockershim%E5%89%8A%E9%99%A4%E5%BE%8C%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\">
<a href=\\"#dockershim%E5%89%8A%E9%99%A4%E5%BE%8C%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\"></a> dockershim削除後のアーキテクチャ</h3>
<p>kubeletがcontainerdまたはCRI-Oと直接通信する構成になった。</p>
<h3 id=\\"containerd\\">
<a href=\\"#containerd\\"></a> containerd</h3>
<ul>
<li>元Dockerの内部コンポーネント、CNCF（Cloud Native Computing Foundation）に寄贈</li>
<li>v2.0でメジャーアップデート（設定フォーマットの見直し等）</li>
<li>GKE、EKS、AKS等のマネージドKubernetesで使用</li>
<li>Kubernetesで広く使われているCRI Runtimeの一つ</li>
</ul>
<ul>
<li>
<strong>gRPC</strong>: Googleが開発した高速なRPC（リモートプロシージャコール）フレームワーク</li>
<li>
<strong>CNI</strong>: Container Network Interface。コンテナのネットワーク設定を行う標準インターフェース</li>
<li>
<strong>スナップショット</strong>: ファイルシステムの差分を効率的に管理する仕組み</li>
</ul>
<h4 id=\\"containerd-2.x%EF%BC%88%E8%A8%AD%E5%AE%9A%E3%81%BE%E3%82%8F%E3%82%8A%E3%81%AE%E8%A6%81%E7%82%B9%EF%BC%89\\">
<a href=\\"#containerd-2.x%EF%BC%88%E8%A8%AD%E5%AE%9A%E3%81%BE%E3%82%8F%E3%82%8A%E3%81%AE%E8%A6%81%E7%82%B9%EF%BC%89\\"></a> containerd 2.x（設定まわりの要点）</h4>
<p>containerdは設定ファイルにバージョンがあり、2.xではversion = 3が推奨。</p>
<ul>
<li>Version 3（containerd 2.xで推奨）: containerd 2.0で導入。プラグインIDなどが一部変更</li>
<li>Version 2（containerd 1.xで推奨）: containerd 1.3で導入。2.xでもサポート</li>
<li>Version 1（デフォルト）: containerd 1.0で導入。containerd 2.0で削除</li>
</ul>
<p>また、NRI（Node Resource Interface）などの機能は「利用できる機能」として把握し、実際に有効化されるか・既定値がどうかは導入環境と設定で確認するのが安全。</p>
<h3 id=\\"cri-o\\">
<a href=\\"#cri-o\\"></a> CRI-O</h3>
<ul>
<li>Red Hat主導</li>
<li>Kubernetes専用設計、最小限の機能</li>
<li>Kubernetesリリースサイクルと同期</li>
<li>OpenShift（Red HatのKubernetesディストリビューション）で標準使用</li>
</ul>
<h4 id=\\"containerd%E3%81%A8cri-o%E3%81%AE%E6%AF%94%E8%BC%83\\">
<a href=\\"#containerd%E3%81%A8cri-o%E3%81%AE%E6%AF%94%E8%BC%83\\"></a> containerdとCRI-Oの比較</h4>
<table>

<tr>
<th>観点</th>
<th>containerd</th>
<th>CRI-O</th>
</tr>

<tr>
<td>汎用性</td>
<td>Kubernetes以外でも使用可</td>
<td>Kubernetes専用</td>
</tr>
<tr>
<td>機能</td>
<td>多機能</td>
<td>最小限</td>
</tr>
<tr>
<td>採用</td>
<td>マネージドK8sの大半</td>
<td>OpenShift中心</td>
</tr>
<tr>
<td>アタックサーフェス</td>
<td>標準的</td>
<td>小さい（機能が少ない分、攻撃対象も少ない）</td>
</tr>

</table>
<h3 id=\\"runtimeclass\\">
<a href=\\"#runtimeclass\\"></a> RuntimeClass</h3>
<p>Kubernetes 1.14で導入。Pod単位でランタイムを選択可能。</p>
<p>apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
apiVersion: v1
kind: Pod
metadata:
  name: untrusted-workload
spec:
  runtimeClassName: gvisor
  containers:
    - name: app
      image: nginx</p>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\"><p><strong>用途別のランタイム選択例</strong></p>

<h2 id=\\"%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3-%2F-cli\\">
<a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3-%2F-cli\\"></a> コンテナエンジン / CLI</h2>
<h3 id=\\"docker-desktop%E6%9C%89%E6%96%99%E5%8C%96\\">
<a href=\\"#docker-desktop%E6%9C%89%E6%96%99%E5%8C%96\\"></a> Docker Desktop有料化</h3>
<p>2021年8月にライセンス変更。従業員250人以上または年間売上1,000万ドル以上の企業は有料。個人・小規模企業・教育・OSSは無料継続。</p>
<h3 id=\\"%E4%B8%BB%E8%A6%81%E3%81%AA%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3\\">
<a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AA%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3\\"></a> 主要なコンテナエンジン</h3>
<h4 id=\\"%E3%83%87%E3%82%B9%E3%82%AF%E3%83%88%E3%83%83%E3%83%97%E5%90%91%E3%81%91gui\\">
<a href=\\"#%E3%83%87%E3%82%B9%E3%82%AF%E3%83%88%E3%83%83%E3%83%97%E5%90%91%E3%81%91gui\\"></a> デスクトップ向けGUI</h4>
<h4 id=\\"cli-1\\">
<a href=\\"#cli-1\\"></a> CLI</h4>
<h4 id=\\"%E3%83%90%E3%83%83%E3%82%AF%E3%82%A8%E3%83%B3%E3%83%89-1\\">
<a href=\\"#%E3%83%90%E3%83%83%E3%82%AF%E3%82%A8%E3%83%B3%E3%83%89-1\\"></a> バックエンド</h4>
<h3 id=\\"docker-engine-%2F-docker-desktop-1\\">
<a href=\\"#docker-engine-%2F-docker-desktop-1\\"></a> Docker Engine / Docker Desktop</h3>
<ul>
<li>
<strong>dockerd</strong>: Docker Daemon。常駐プロセスとしてコンテナを管理する</li>
<li>
<strong>BuildKit</strong>: 次世代のイメージビルドエンジン</li>
<li>エコシステムが充実、ドキュメントが豊富</li>
<li>Docker EngineはApache 2.0ライセンスのOSS</li>
</ul>
<h3 id=\\"podman-1\\">
<a href=\\"#podman-1\\"></a> Podman</h3>
<p>デーモンレスアーキテクチャ。各コンテナが独立したプロセスとして動作。</p>
<p><strong>Dockerの場合</strong></p>
<p><strong>Podmanの場合</strong></p>
<ul>
<li>
<strong>デーモンレス</strong>: 常駐プロセスが不要。dockerdのような単一障害点がない</li>
<li>
<strong>conmon</strong>: Container Monitor。各コンテナの監視プロセス</li>
</ul>
<h4 id=\\"%E3%82%B3%E3%83%B3%E3%83%9D%E3%83%BC%E3%83%8D%E3%83%B3%E3%83%88-1\\">
<a href=\\"#%E3%82%B3%E3%83%B3%E3%83%9D%E3%83%BC%E3%83%8D%E3%83%B3%E3%83%88-1\\"></a> コンポーネント</h4>
<table>

<tr>
<th>コンポーネント</th>
<th>役割</th>
</tr>

<tr>
<td><strong>podman</strong></td>
<td>メインCLI、Docker互換コマンド</td>
</tr>
<tr>
<td><strong>conmon</strong></td>
<td>コンテナごとの監視プロセス</td>
</tr>
<tr>
<td><strong>crun</strong></td>
<td>デフォルトOCIランタイム</td>
</tr>
<tr>
<td><strong>Buildah</strong></td>
<td>イメージビルドツール</td>
</tr>
<tr>
<td><strong>Skopeo</strong></td>
<td>イメージ転送・検査ツール</td>
</tr>
<tr>
<td><strong>Podman Desktop</strong></td>
<td>GUIツール</td>
</tr>

</table>
<h4 id=\\"pod%E6%A9%9F%E8%83%BD-1\\">
<a href=\\"#pod%E6%A9%9F%E8%83%BD-1\\"></a> Pod機能</h4>
<p>KubernetesのPod（複数コンテナをグループ化する単位）と同じ概念をローカルで再現できる。</p>
<pre><code class=\\"language-bash\\"># Podを作成
podman pod create --name myapp -p 8080:80

# Podにコンテナを追加
podman run -d --pod myapp nginx
podman run -d --pod myapp redis

# Kubernetes用YAMLを生成
podman generate kube myapp &gt; myapp.yaml

# YAMLからPodを起動
podman play kube myapp.yaml
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h4 id=\\"rootless-1\\">
<a href=\\"#rootless-1\\"></a> Rootless</h4>
<p>設計段階からRootless前提。コンテナ内rootはホスト上の非特権ユーザーにマッピング。</p>
<p>コンテナ内でrootとして動作しても、ホスト上では一般ユーザー権限。万が一コンテナから脱出されてもホストのroot権限は奪われない。</p>
<h4 id=\\"quadlet-1\\">
<a href=\\"#quadlet-1\\"></a> Quadlet</h3>
<p>Podman 4.4以降。systemd（Linuxのサービス管理システム）のユニットファイルとしてコンテナを管理。</p>
<pre><code class=\\"language-ini\\"># ~/.config/containers/systemd/nginx.container
[Container]
Image=docker.io/nginx:latest
PublishPort=8080:80

[Service]
Restart=always

[Install]
WantedBy=default.target
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h4 id=\\"%E6%8E%A1%E7%94%A8%E7%8A%B6%E6%B3%81-1\\">
<a href=\\"#%E6%8E%A1%E7%94%A8%E7%8A%B6%E6%B3%81-1\\"></a> 採用状況</h4>
<ul>
<li>RHEL系を中心に標準ツールとして採用されることが多い</li>
<li>Podman Desktopのプロジェクト区分（CNCF等）は都度公式発表を要確認</li>
</ul>
<h3 id=\\"nerdctl-1\\">
<a href=\\"#nerdctl-1\\"></a> nerdctl</h3>
<p>containerd用Docker互換CLI。</p>
<table>

<tr>
<th>機能</th>
<th>説明</th>
</tr>

<tr>
<td>Docker CLIと同じコマンド体系</td>
<td>学習コストが低い</td>
</tr>
<tr>
<td>Compose対応</td>
<td>docker-compose.ymlがそのまま使える</td>
</tr>
<tr>
<td>lazy-pulling</td>
<td>eStargz形式によりイメージ全体をダウンロードせずにコンテナを起動可能</td>
</tr>
<tr>
<td>暗号化イメージ</td>
<td>OCICryptによるイメージの暗号化に対応</td>
</tr>
<tr>
<td>Wasmネイティブサポート</td>
<td>WebAssemblyをコンテナとして実行可能</td>
</tr>

</table>
<p>Rancher Desktop、Lima、Finchで使用されている。</p>
<h3 id=\\"colima-1\\">
<a href=\\"#colima-1\\"></a> Colima</h3>
<p>macOS向け軽量ツール。Lima（Linux virtual machine）ベース。</p>
<pre><code class=\\"language-bash\\">brew install colima docker
colima start
colima start --runtime containerd
colima start --cpu 4 --memory 8 --disk 100
colima start --kubernetes
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h3 id=\\"orbstack-1\\">
<a href=\\"#orbstack-1\\"></a> OrbStack</h3>
<p>macOS専用、パフォーマンス特化。</p>
<table>

<tr>
<th>特徴</th>
<th>説明</th>
</tr>

<tr>
<td>起動約2秒</td>
<td>Docker Desktopより高速</td>
</tr>
<tr>
<td>動的メモリ管理</td>
<td>使用量に応じてメモリを確保・解放</td>
</tr>
<tr>
<td>ドメインアクセス</td>
<td>
container-name.orb.local でコンテナにアクセス可能</td>
</tr>
<tr>
<td>Docker互換</td>
<td>Docker CLI、Composeがそのまま動作</td>
</tr>
<tr>
<td>価格</td>
<td>有料（個人は無料）</td>
</tr>

</table>
<h3 id=\\"rancher-desktop-1\\">
<a href=\\"#rancher-desktop-1\\"></a> Rancher Desktop</h3>
<table>

<tr>
<th>特徴</th>
<th>説明</th>
</tr>

<tr>
<td>ランタイム選択</td>
<td>containerd/dockerdを切り替え可能</td>
</tr>
<tr>
<td>Kubernetes統合</td>
<td>k3s（軽量Kubernetes）によるローカルK8s環境</td>
</tr>

</table>
<h3 id=\\"lxc-%2F-lxd-(incus)-1\\">
<a href=\\"#lxc-%2F-lxd-(incus)-1\\"></a> LXC / LXD (Incus)</h3>
<p>システムコンテナ。Docker/Podmanの「アプリケーションコンテナ」とは異なる。</p>
<table>

<tr>
<th>観点</th>
<th>アプリケーションコンテナ</th>
<th>システムコンテナ</th>
</tr>

<tr>
<td>起動対象</td>
<td>単一プロセス</td>
<td>完全なOS（init含む）</td>
</tr>
<tr>
<td>用途</td>
<td>マイクロサービス</td>
<td>VM代替、開発環境</td>
</tr>
<tr>
<td>ライフサイクル</td>
<td>短命（使い捨て）</td>
<td>長寿命（アップデートして使い続ける）</td>
</tr>

</table>
<p>2023年にCanonicalの方針変更によりIncusがフォーク。</p>
<h3 id=\\"%E6%A9%9F%E8%83%BD%E6%AF%94%E8%BC%83-1\\">
<a href=\\"#%E6%A9%9F%E8%83%BD%E6%AF%94%E8%BC%83-1\\"></a> 機能比較</h3>
<table>

<tr>
<th>機能</th>
<th>Docker</th>
<th>Podman</th>
<th>nerdctl</th>
<th>LXD</th>
</tr>

<tr>
<td>Rootless</td>
<td>後付け対応</td>
<td>設計時から対応</td>
<td>対応</td>
<td>限定的</td>
</tr>
<tr>
<td>デーモンレス</td>
<td>×</td>
<td>○</td>
<td>○</td>
<td>×</td>
</tr>
<tr>
<td>Pod</td>
<td>×</td>
<td>○</td>
<td>○</td>
<td>×</td>
</tr>
<tr>
<td>Compose</td>
<td>○</td>
<td>○</td>
<td>○</td>
<td>×</td>
</tr>
<tr>
<td>K8s YAML生成</td>
<td>×</td>
<td>○</td>
<td>○</td>
<td>×</td>
</tr>
<tr>
<td>systemd統合</td>
<td>限定的</td>
<td>Quadlet</td>
<td>限定的</td>
<td>○</td>
</tr>

</table>
<h3 id=\\"%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Amacos-1\\">
<a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Amacos-1\\"></a> 選択基準：macOS</h3>
<h3 id=\\"%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Alinux-1\\">
<a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Alinux-1\\"></a> 選択基準：Linux</h3>
<h3 id=\\"%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Awindows-1\\">
<a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Awindows-1\\"></a> 選択基準：Windows</h3>

<h2 id=\\"%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%83%93%E3%83%AB%E3%83%89%E3%83%84%E3%83%BC%E3%83%AB\\">
<a href=\\"#%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%83%93%E3%83%AB%E3%83%89%E3%83%84%E3%83%BC%E3%83%AB\\"></a> イメージビルドツール</h2>
<h3 id=\\"%E7%B5%B1%E5%90%88%E5%9E%8B-1\\">
<a href=\\"#%E7%B5%B1%E5%90%88%E5%9E%8B-1\\"></a> 統合型</h3>
<h3 id=\\"%E3%82%B9%E3%82%BF%E3%83%B3%E3%83%89%E3%82%A2%E3%83%AD%E3%83%B3-1\\">
<a href=\\"#%E3%82%B9%E3%82%BF%E3%83%B3%E3%83%89%E3%82%A2%E3%83%AD%E3%83%B3-1\\"></a> スタンドアロン</h3>
<h3 id=\\"%E8%BB%A2%E9%80%81%E3%83%BB%E6%A4%9C%E6%9F%BB-1\\">
<a href=\\"#%E8%BB%A2%E9%80%81%E3%83%BB%E6%A4%9C%E6%9F%BB-1\\"></a> 転送・検査</h3>
<h3 id=\\"buildkit-1\\">
<a href=\\"#buildkit-1\\"></a> BuildKit</h3>
<p>Docker 18.09以降に搭載された次世代ビルドエンジン。</p>
<table>

<tr>
<th>機能</th>
<th>説明</th>
</tr>

<tr>
<td>並列ビルド</td>
<td>DAG（有向非巡回グラフ）に基づいて依存関係のないステップを並列実行</td>
</tr>
<tr>
<td>効率的なキャッシュ</td>
<td>レイヤー単位でキャッシュを再利用</td>
</tr>
<tr>
<td>シークレットマウント</td>
<td>秘密情報をビルド時のみ利用可能にし、イメージには含めない</td>
</tr>
<tr>
<td>SSHエージェント転送</td>
<td>SSH鍵をイメージに残さずにプライベートリポジトリからクローン可能</td>
</tr>
<tr>
<td>マルチプラットフォーム</td>
<td>複数アーキテクチャ（amd64、arm64等）向けに同時ビルド</td>
</tr>

</table>
<pre><code class=\\"language-dockerfile\\"># syntax=docker/dockerfile:1
FROM golang:1.21

# シークレットマウント：ビルド時のみ利用可能
RUN --mount=type=secret,id=github_token \\
    GITHUB_TOKEN=$(cat /run/secrets/github_token) \\
    go get private-repo.com/pkg

# キャッシュマウント：ビルドキャッシュを永続化
RUN --mount=type=cache,target=/root/.cache/go-build \\
    go build -o /app
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h3 id=\\"buildah-1\\">
<a href=\\"#buildah-1\\"></a> Buildah</h3>
<p>Red Hat製のイメージビルド専用ツール。</p>
<table>

<tr>
<th>特徴</th>
<th>説明</th>
</tr>

<tr>
<td>デーモン不要</td>
<td>dockerdなしでビルド可能</td>
</tr>
<tr>
<td>Dockerfileなし</td>
<td>シェルスクリプト的にイメージを構築可能</td>
</tr>
<tr>
<td>中間イメージなし</td>
<td>ディスク効率が良い</td>
</tr>

</table>
<pre><code class=\\"language-bash\\">container=$(buildah from fedora)
buildah run $container dnf install -y nginx
buildah config --cmd \\"/usr/sbin/nginx -g 'daemon off;'\\" $container
buildah commit $container my-nginx
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h3 id=\\"kaniko-1\\">
<a href=\\"#kaniko-1\\"></a> Kaniko</h3>
<p>Kubernetes環境向けビルドツール。Googleがメンテナンスしているが、近年はBuildKitやkoの利用が拡大している。ただし、特権を持たない特定のCI環境では依然として重要な選択肢である。</p>
<table>

<tr>
<th>特徴</th>
<th>説明</th>
</tr>

<tr>
<td>特権不要</td>
<td>Docker daemonやroot権限なしでビルド</td>
</tr>
<tr>
<td>K8sネイティブ</td>
<td>Kubernetesのジョブとして実行可能</td>
</tr>

</table>
<pre><code class=\\"language-yaml\\">apiVersion: v1
kind: Pod
metadata:
  name: kaniko-build
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args:
    - \\"--dockerfile=Dockerfile\\"
    - \\"--context=git://github.com/myrepo/myapp\\"
    - \\"--destination=myregistry.com/myapp:latest\\"
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<h3 id=\\"ko-1\\">
<a href=\\"#ko-1\\"></a> ko</h3>
<p>Go専用ビルドツール。</p>
<pre><code class=\\"language-bash\\"># Dockerfileなしでビルド＆プッシュ
ko build ./cmd/myapp

# Kubernetesマニフェストに直接埋め込んでデプロイ
ko apply -f deployment.yaml
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">
<p>GoのソースコードからDockerfileを書かずに直接コンテナイメージを生成できる。</p>
<h3 id=\\"skopeo-1\\">
<a href=\\"#skopeo-1\\"></a> Skopeo</h3>
<p>イメージの転送・検査専用ツール。</p>
<pre><code class=\\"language-bash\\"># レジストリ間でイメージをコピー（ローカルにpull不要）
skopeo copy docker://docker.io/nginx docker://myregistry.com/nginx

# イメージのメタデータを確認（pull不要）
skopeo inspect docker://docker.io/nginx

# マルチアーキテクチャのマニフェストを確認
skopeo inspect --raw docker://nginx | jq
</code></pre>
<img src=\\"https://static.zenn.studio/images/copy-icon.svg\\"><img src=\\"https://static.zenn.studio/images/wrap-icon.svg\\">

<h2 id=\\"%E3%81%93%E3%81%93%E6%95%B0%E5%B9%B4%E3%81%AE%E6%B5%81%E3%82%8C\\">
<a href=\\"#%E3%81%93%E3%81%93%E6%95%B0%E5%B9%B4%E3%81%AE%E6%B5%81%E3%82%8C\\"></a> ここ数年の流れ</h2>
<h3 id=\\"%E6%99%82%E7%B3%BB%E5%88%97-1\\">
<a href=\\"#%E6%99%82%E7%B3%BB%E5%88%97-1\\"></a> 時系列</h3>
<h3 id=\\"%E7%8F%BE%E5%9C%A8%E3%81%AE%E5%B8%82%E5%A0%B4-1\\">
<a href=\\"#%E7%8F%BE%E5%9C%A8%E3%81%AE%E5%B8%82%E5%A0%B4-1\\"></a> 現在の市場</h3>
<p>※利用状況の割合は出典により大きく変動するため、本記事では断定的な割合は置かない。</p>
<table>

<tr>
<th>領域</th>
<th>主な選択肢</th>
<th>理由</th>
</tr>

<tr>
<td>本番Kubernetes</td>
<td>containerd</td>
<td>軽量・高速、CNCF標準</td>
</tr>
<tr>
<td>開発環境</td>
<td>Docker</td>
<td>エコシステム、ドキュメント</td>
</tr>
<tr>
<td>セキュリティ重視</td>
<td>Podman</td>
<td>Rootless・デーモンレス</td>
</tr>
<tr>
<td>OpenShift</td>
<td>CRI-O</td>
<td>Red Hat標準</td>
</tr>

</table>
<h3 id=\\"%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E3%81%AE%E3%83%AC%E3%83%99%E3%83%AB-1\\">
<a href=\\"#%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E3%81%AE%E3%83%AC%E3%83%99%E3%83%AB-1\\"></a> セキュリティランタイムのレベル</h3>
<table>

<tr>
<th>レベル</th>
<th>ランタイム</th>
<th>ユースケース</th>
</tr>

<tr>
<td>標準</td>
<td>runc</td>
<td>一般ワークロード</td>
</tr>
<tr>
<td>強化</td>
<td>gVisor</td>
<td>マルチテナント</td>
</tr>
<tr>
<td>最強</td>
<td>Kata</td>
<td>金融・医療</td>
</tr>
<tr>
<td>機密</td>
<td>Confidential Containers</td>
<td>AI/ML機密データ</td>
</tr>

</table>
<p><strong>Confidential Computing</strong>: ハードウェアレベルでメモリを暗号化し、クラウド事業者でさえもデータにアクセスできないようにする技術。Intel SGX、AMD SEV、ARM CCAなどが対応。NVIDIAがKata Containers + Confidential ContainersでGPUワークロード保護を進めている。</p>
<h3 id=\\"webassembly%EF%BC%88wasm%EF%BC%89-1\\">
<a href=\\"#webassembly%EF%BC%88wasm%EF%BC%89-1\\"></a> WebAssembly（Wasm）</h3>
<p>コンテナの次世代技術として注目されている。</p>
<table>

<tr>
<th>観点</th>
<th>コンテナ</th>
<th>WebAssembly</th>
</tr>

<tr>
<td>サイズ</td>
<td>数百MB〜GB</td>
<td>KB〜数MB</td>
</tr>
<tr>
<td>起動時間</td>
<td>数百ms</td>
<td>数ms</td>
</tr>
<tr>
<td>隔離方式</td>
<td>OS namespace</td>
<td>サンドボックスVM</td>
</tr>
<tr>
<td>ポータビリティ</td>
<td>OS/アーキテクチャ依存</td>
<td>完全ポータブル</td>
</tr>
<tr>
<td>言語</td>
<td>制限なし</td>
<td>Rust, Go, C/C++等</td>
</tr>

</table>
<ul>
<li>
<strong>WASI</strong>: WebAssembly System Interface。ファイルやネットワークなどのシステムリソースにアクセスするための標準API</li>
<li>WASI 0.2（Component Model/WIT 系）などの動きが進んでいる</li>
</ul>
<table>

<tr>
<th>プロジェクト</th>
<th>状況</th>
</tr>

<tr>
<td>wasmCloud</td>
<td>継続的に開発が進む（プロジェクト区分は要確認）</td>
</tr>
<tr>
<td>containerd</td>
<td>Wasmサポート追加（実験的）</td>
</tr>

</table>
<h3 id=\\"ebpf-1\\">
<a href=\\"#ebpf-1\\"></a> eBPF</h3>
<p>eBPF（extended Berkeley Packet Filter）がコンテナのネットワーキング・可観測性で標準化。</p>
<ul>
<li>
<strong>eBPF</strong>: カーネル内でプログラムを実行できる技術。ネットワーク処理やセキュリティ監視を高速に行える</li>
<li>
<strong>iptables</strong>: 従来のLinuxファイアウォール/パケット処理機構。ルールが複雑になると性能が低下</li>
</ul>
<p>Cilium、CalicoなどのCNIプラグインがiptablesの代替としてeBPFを使用。</p>

<h2 id=\\"%E4%BB%8A%E5%BE%8C%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\">
<a href=\\"#%E4%BB%8A%E5%BE%8C%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\"></a> 今後について</h2>
<h3 id=\\"%E3%83%88%E3%83%AC%E3%83%B3%E3%83%89-1\\">
<a href=\\"#%E3%83%88%E3%83%AC%E3%83%B3%E3%83%89-1\\"></a> トレンド</h3>
<table>

<tr>
<th>トレンド</th>
<th>内容</th>
</tr>

<tr>
<td>マルチランタイム</td>
<td>runc/gVisor/Kata/Wasmの併用が標準化</td>
</tr>
<tr>
<td>Confidential Computing</td>
<td>AI/MLでハードウェア暗号化が標準化</td>
</tr>
<tr>
<td>WebAssembly</td>
<td>エッジ・サーバーレスでコンテナの代替</td>
</tr>
<tr>
<td>サプライチェーンセキュリティ</td>
<td>イメージ署名、SBOM、attestationが必須化</td>
</tr>

</table>
<ul>
<li>
<strong>SBOM</strong>: Software Bill of Materials。ソフトウェアの部品表。含まれるライブラリやその依存関係を一覧化したもの</li>
<li>
<strong>attestation</strong>: 証明。ビルド環境やプロセスが改ざんされていないことを検証可能にする仕組み</li>
</ul>
<h3 id=\\"%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83-1\\">
<a href=\\"#%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83-1\\"></a> 開発環境</h3>
<h3 id=\\"%E6%9C%AC%E7%95%AAk8s-1\\">
<a href=\\"#%E6%9C%AC%E7%95%AAk8s-1\\"></a> 本番K8s</h3>
<h3 id=\\"%E3%82%A8%E3%83%83%E3%82%B8%2F%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%83%AC%E3%82%B9-1\\">
<a href=\\"#%E3%82%A8%E3%83%83%E3%82%B8%2F%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%83%AC%E3%82%B9-1\\"></a> エッジ/サーバーレス</h3>
<h3 id=\\"oci-runtime-1\\">
<a href=\\"#oci-runtime-1\\"></a> OCI Runtime</h3>

<h2 id=\\"%E3%81%BE%E3%81%A8%E3%82%81-1\\">
<a href=\\"#%E3%81%BE%E3%81%A8%E3%82%81-1\\"></a> まとめ</h2>
<ol>
<li>
<strong>標準化完了</strong>: OCI/CRIでコンポーネント交換可能</li>
<li>
<strong>棲み分け</strong>: 開発はDocker、本番はcontainerd、セキュリティはPodman</li>
<li>
<strong>セキュリティ選択肢</strong>: Rootless → gVisor → Kata → Confidential Computing</li>
<li>
<strong>次世代移行</strong>: Wasmがエッジ・サーバーレスから浸透</li>
<li>
<strong>可観測性進化</strong>: eBPFによるカーネルレベル監視が標準化</li>
</ol>
<table>

<tr>
<th>ユースケース</th>
<th>構成</th>
</tr>

<tr>
<td>スタートアップ・個人</td>
<td>Docker Desktop / Colima</td>
</tr>
<tr>
<td>エンタープライズ開発</td>
<td>Podman + Podman Desktop</td>
</tr>
<tr>
<td>本番Kubernetes</td>
<td>containerd</td>
</tr>
<tr>
<td>マルチテナントSaaS</td>
<td>containerd + gVisor</td>
</tr>
<tr>
<td>金融・医療</td>
<td>containerd + Kata Containers</td>
</tr>
<tr>
<td>エッジ・IoT</td>
<td>WebAssembly</td>
</tr>
<tr>
<td>AI/ML機密処理</td>
<td>Kata + Confidential Containers</td>
</tr>

</table>

<h2 id=\\"%E5%8F%82%E8%80%83%E3%83%AA%E3%83%B3%E3%82%AF-1\\">
<a href=\\"#%E5%8F%82%E8%80%83%E3%83%AA%E3%83%B3%E3%82%AF-1\\"></a> 参考リンク</h2>
<ul>
<li><a href=\\"https://opencontainers.org/\\">OCI</a></li>
<li><a href=\\"https://containerd.io/\\">containerd</a></li>
<li><a href=\\"https://podman.io/\\">Podman</a></li>
<li><a href=\\"https://gvisor.dev/\\">gVisor</a></li>
<li><a href=\\"https://katacontainers.io/\\">Kata Containers</a></li>
<li><a href=\\"https://wasmcloud.com/\\">wasmCloud</a></li>
<li><a href=\\"https://landscape.cncf.io/\\">CNCF Landscape</a></li>
</ul>

!
<p>可能な限り公式ドキュメント等で裏取りを行っていますが、この記事は個人的な調査メモであり、内容の正確性を保証するものではありません。
技術選定や本番環境への導入に際しては、必ず各プロジェクトの公式ドキュメントをご確認ください。</p>

3113<a href=\\"https://twitter.com/intent/tweet?url=https://zenn.dev/nossa/articles/a6f5b342ad83f0&text=%E3%80%902026%E5%B9%B41%E6%9C%88%E3%80%91%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E5%91%A8%E8%BE%BA%E3%81%AE%E8%AA%BF%E6%9F%BB%E3%83%A1%E3%83%A2%EF%BC%9ADocker%E4%BB%A5%E5%A4%96%E3%81%AB%E4%BD%95%E3%81%8C%E3%81%82%E3%82%8B%E3%81%AE%E3%81%8B%E3%80%81%E4%BB%8A%E3%81%A9%E3%81%86%E3%81%AA%E3%81%A3%E3%81%A6%E3%81%84%E3%82%8B%E3%81%AE%E3%81%8B%EF%BD%9C%E3%81%AE%E3%81%95&hashtags=zenn\\" id=\\"gtm-article-footer-tweet\\"></a><a href=\\"http://www.facebook.com/sharer.php?u=https://zenn.dev/nossa/articles/a6f5b342ad83f0\\" id=\\"gtm-article-footer-facebook\\"></a><a href=\\"https://b.hatena.ne.jp/add?mode=confirm&url=https://zenn.dev/nossa/articles/a6f5b342ad83f0&title=%E3%80%902026%E5%B9%B41%E6%9C%88%E3%80%91%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E5%91%A8%E8%BE%BA%E3%81%AE%E8%AA%BF%E6%9F%BB%E3%83%A1%E3%83%A2%EF%BC%9ADocker%E4%BB%A5%E5%A4%96%E3%81%AB%E4%BD%95%E3%81%8C%E3%81%82%E3%82%8B%E3%81%AE%E3%81%8B%E3%80%81%E4%BB%8A%E3%81%A9%E3%81%86%E3%81%AA%E3%81%A3%E3%81%A6%E3%81%84%E3%82%8B%E3%81%AE%E3%81%8B%EF%BD%9C%E3%81%AE%E3%81%95\\" id=\\"gtm-article-footer-hatena-bookmark\\"></a><a href=\\"https://zenn.dev/nossa\\"><img alt=\\"のさ\\" src=\\"https://lh3.googleusercontent.com/a-/AOh14GixT6nDD7c4euj57-Hfjct1YuHoMUSccfNRRBKq=s96-c\\"></a><a href=\\"https://zenn.dev/nossa\\">のさ</a><p>Full-cycle oriented, currently studying platform engineering</p>フォローバッジを贈って著者を応援しよう<p>バッジを受け取った著者にはZennから現金やAmazonギフトカードが還元されます。</p>バッジを贈る<h3>Discussion</h3><img src=\\"https://static.zenn.studio/images/drawing/discussion.png\\">91<img>記事についてコメントする<p><a href=\\"https://zenn.dev/guideline\\">コミュニティガイドライン</a>に則った投稿をしましょう。</p><a href=\\"https://zenn.dev/nossa\\"><img alt=\\"のさ\\" src=\\"https://lh3.googleusercontent.com/a-/AOh14GixT6nDD7c4euj57-Hfjct1YuHoMUSccfNRRBKq=s96-c\\"></a><a href=\\"https://zenn.dev/nossa\\">のさ</a>フォロー<p>Full-cycle oriented, currently studying platform engineering</p>バッジを贈る<a href=\\"https://zenn.dev/faq#badges\\">バッジを贈るとは</a>目次<ol><li><a href=\\"#%E3%81%93%E3%81%AE%E8%A8%98%E4%BA%8B%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\">この記事について</a></li><li><a href=\\"#%E7%9B%AE%E6%AC%A1\\">目次</a></li><li><a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E6%8A%80%E8%A1%93%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E6%A7%8B%E9%80%A0\\">コンテナ技術のレイヤー構造</a><ol><li><a href=\\"#%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC%E5%90%91%E3%81%91%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC\\">ユーザー向けレイヤー</a></li><li><a href=\\"#%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89\\">高レベルランタイム（CRI Runtime）</a></li><li><a href=\\"#%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89\\">低レベルランタイム（OCI Runtime）</a></li><li><a href=\\"#linux%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB\\">Linuxカーネル</a></li><li><a href=\\"#%E5%90%84%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%81%AE%E5%BD%B9%E5%89%B2\\">各レイヤーの役割</a></li></ol></li><li><a href=\\"#%E4%BD%8E%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88oci-runtime%EF%BC%89-1\\">低レベルランタイム（OCI Runtime）</a><ol><li><a href=\\"#oci%E6%A8%99%E6%BA%96\\">OCI標準</a></li><li><a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E6%A8%99%E6%BA%96%E5%AE%9F%E8%A3%85\\">主要なOCI Runtime：標準実装</a></li><li><a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E9%87%8D%E8%A6%96\\">主要なOCI Runtime：パフォーマンス重視</a></li><li><a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AAoci-runtime%EF%BC%9A%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E9%87%8D%E8%A6%96\\">主要なOCI Runtime：セキュリティ重視</a></li><li><a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96\\">選択基準</a></li></ol></li><li><a href=\\"#%E9%AB%98%E3%83%AC%E3%83%99%E3%83%AB%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%EF%BC%88cri-runtime%EF%BC%89-1\\">高レベルランタイム（CRI Runtime）</a><ol><li><a href=\\"#kubernetes%E3%81%A8cri%E3%81%AE%E7%B5%8C%E7%B7%AF\\">KubernetesとCRIの経緯</a></li><li><a href=\\"#dockershim%E5%89%8A%E9%99%A4%E5%89%8D%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\">dockershim削除前のアーキテクチャ</a></li><li><a href=\\"#dockershim%E5%89%8A%E9%99%A4%E5%BE%8C%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3\\">dockershim削除後のアーキテクチャ</a></li><li><a href=\\"#containerd\\">containerd</a></li><li><a href=\\"#cri-o\\">CRI-O</a></li><li><a href=\\"#runtimeclass\\">RuntimeClass</a></li></ol></li><li><a href=\\"#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3-%2F-cli\\">コンテナエンジン / CLI</a><ol><li><a href=\\"#docker-desktop%E6%9C%89%E6%96%99%E5%8C%96\\">Docker Desktop有料化</a></li><li><a href=\\"#%E4%B8%BB%E8%A6%81%E3%81%AA%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3\\">主要なコンテナエンジン</a></li><li><a href=\\"#docker-engine-%2F-docker-desktop\\">Docker Engine / Docker Desktop</a></li><li><a href=\\"#podman\\">Podman</a></li><li><a href=\\"#nerdctl\\">nerdctl</a></li><li><a href=\\"#colima\\">Colima</a></li><li><a href=\\"#orbstack\\">OrbStack</a></li><li><a href=\\"#rancher-desktop\\">Rancher Desktop</a></li><li><a href=\\"#lxc-%2F-lxd-(incus)\\">LXC / LXD (Incus)</a></li><li><a href=\\"#%E6%A9%9F%E8%83%BD%E6%AF%94%E8%BC%83\\">機能比較</a></li><li><a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Amacos\\">選択基準：macOS</a></li><li><a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Alinux\\">選択基準：Linux</a></li><li><a href=\\"#%E9%81%B8%E6%8A%9E%E5%9F%BA%E6%BA%96%EF%BC%9Awindows\\">選択基準：Windows</a></li></ol></li><li><a href=\\"#%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%83%93%E3%83%AB%E3%83%89%E3%83%84%E3%83%BC%E3%83%AB\\">イメージビルドツール</a><ol><li><a href=\\"#%E7%B5%B1%E5%90%88%E5%9E%8B\\">統合型</a></li><li><a href=\\"#%E3%82%B9%E3%82%BF%E3%83%B3%E3%83%89%E3%82%A2%E3%83%AD%E3%83%B3\\">スタンドアロン</a></li><li><a href=\\"#%E8%BB%A2%E9%80%81%E3%83%BB%E6%A4%9C%E6%9F%BB\\">転送・検査</a></li><li><a href=\\"#buildkit\\">BuildKit</a></li><li><a href=\\"#buildah\\">Buildah</a></li><li><a href=\\"#kaniko\\">Kaniko</a></li><li><a href=\\"#ko\\">ko</a></li><li><a href=\\"#skopeo\\">Skopeo</a></li></ol></li><li><a href=\\"#%E3%81%93%E3%81%93%E6%95%B0%E5%B9%B4%E3%81%AE%E6%B5%81%E3%82%8C\\">ここ数年の流れ</a><ol><li><a href=\\"#%E6%99%82%E7%B3%BB%E5%88%97\\">時系列</a></li><li><a href=\\"#%E7%8F%BE%E5%9C%A8%E3%81%AE%E5%B8%82%E5%A0%B4\\">現在の市場</a></li><li><a href=\\"#%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E3%83%A9%E3%83%B3%E3%82%BF%E3%82%A4%E3%83%A0%E3%81%AE%E3%83%AC%E3%83%99%E3%83%AB\\">セキュリティランタイムのレベル</a></li><li><a href=\\"#webassembly%EF%BC%88wasm%EF%BC%89\\">WebAssembly（Wasm）</a></li><li><a href=\\"#ebpf\\">eBPF</a></li></ol></li><li><a href=\\"#%E4%BB%8A%E5%BE%8C%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6\\">今後について</a><ol><li><a href=\\"#%E3%83%88%E3%83%AC%E3%83%B3%E3%83%89\\">トレンド</a></li><li><a href=\\"#%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83\\">開発環境</a></li><li><a href=\\"#%E6%9C%AC%E7%95%AAk8s\\">本番K8s</a></li><li><a href=\\"#%E3%82%A8%E3%83%83%E3%82%B8%2F%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%83%AC%E3%82%B9\\">エッジ/サーバーレス</a></li><li><a href=\\"#oci-runtime\\">OCI Runtime</a></li></ol></li><li><a href=\\"#%E3%81%BE%E3%81%A8%E3%82%81\\">まとめ</a></li><li><a href=\\"#%E5%8F%82%E8%80%83%E3%83%AA%E3%83%B3%E3%82%AF\\">参考リンク</a></li></ol><p>Zennからのお知らせ</p><a href=\\"https://zenn.dev/hackathons/google-cloud-japan-ai-hackathon-vol4\\" id=\\"google-cloud-japan-ai-hackathon-vol4-article-right\\"><img alt=\\"第4回 Agentic AI Hackathon with Google Cloud 受付開始！\\" src=\\"https://static.zenn.studio/permanent/hackathon/google-cloud-japan-ai-hackathon-vol4/bannerIcon.png\\"><p>第4回 Agentic AI Hackathon with Google Cloud 開催中！</p></a><p id=\\"__next-route-announcer__\\">【2026年1月】コンテナランタイム周辺の調査メモ：Docker以外に何があるのか、今どうなっているのか</p>
```
