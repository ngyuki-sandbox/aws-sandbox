# aws-codebuild-gitlab-docker-runner

AWS CodeBuild 上で GitLab Runner（ Docker executor / Shell executor ）をオンデマンド実行するための Terraform 構成。

> - https://x.com/ngyuki/status/1896168997693120865
> - https://ngyuki.hatenablog.com/entry/2026/08/30/100727

## 概要

AWS CodeBuild が提供する公式の GitLab Runner 統合は Shell 実行が基本であり、ジョブ実行ごとに Runner を動的登録・削除する仕様となっている。

本構成では事前に GitLab Runner を登録しておき、GitLab の Job Webhook を契機に Lambda 経由で CodeBuild を起動して `gitlab-runner run-single` を実行することで、Docker executor および Shell executor の両方をオンデマンドで実行する。

```mermaid
flowchart LR
    gitlab[GitLab] -->|Job Hook| functionUrl[Lambda Function URL]
    functionUrl --> lambda[AWS Lambda]
    lambda -->|StartBuild| codebuild[AWS CodeBuild]
    codebuild --> runner[GitLab Runner]
    runner --> executor[Docker / Shell executor]
```

## セットアップ

GitLab Provider の認証のため Terraform 実行時に `TF_VAR_gitlab_token` を環境変数に設定する。

```sh
export TF_VAR_gitlab_token="glpat-xxxxxxxxxxxxxxxxxxxx"
terraform init
terraform apply
```

**NOTE:**
Job Webhook を契機に開始した Lambda でジョブのタグ（ `tag_list` ）を取得するために GitLab の PAT を利用している。有効期限は最大 365 日のため、定期的に `terraform apply` でローテートが必要。

## .gitlab-ci.yml の例

ジョブの `tags` に応じて、Docker executor と Shell executor が自動的に切り替わる。

```yaml
stages:
  - test

# Docker executor によるコンテナ内実行
docker:
  stage: test
  tags:
    - aws-codebuild-docker-runner
  image:
    name: public.ecr.aws/docker/library/alpine
  script:
    - cat /etc/os-release

# Docker-in-Docker (dind) によるコンテナビルド
dind:
  stage: test
  tags:
    - aws-codebuild-docker-runner
  image:
    name: public.ecr.aws/docker/library/docker:cli
  services:
    - name: public.ecr.aws/docker/library/docker:dind
      alias: docker
  variables:
    DOCKER_TLS_CERTDIR: ""
    DOCKER_HOST: tcp://docker:2375
  script:
    - cat /etc/os-release
    - docker version

# Shell executor による CodeBuild ホスト直接実行
shell:
  stage: test
  tags:
    - aws-codebuild-shell-runner
  script:
    - cat /etc/os-release
    - docker version
```

## アーキテクチャと設計判断

### 1. なぜ Lambda から GitLab REST API を呼び出しているのか？

- **Job Webhook ペイロードに `tag_list` が含まれない問題**
  GitLab の Job Webhook ペイロードにはジョブ定義のタグ（ `tag_list` ）が含まれていない（ https://gitlab.com/gitlab-org/gitlab/-/issues/467657 ）。
  そのため、ジョブが要求しているタグを判別して起動要否や executor を決定するために、Lambda から GitLab REST API（ `/jobs/:id` ）を呼び出してタグを取得している

### 2. なぜ Runner（トークン）を Docker 用と Shell 用の 2 つに分けているのか？

- **1 つの Runner で分岐できない理由（ジョブ横取り事故の防止）**
  `gitlab-runner run-single` は特定の Job ID を指定してジョブを取得する機能がなく、対象 Runner トークンに紐づく pending ジョブの先頭を無条件に dequeue する。
  もし Runner が 1 つだと、複数ジョブが同時に pending になった際に、Shell 用に起動した CodeBuild がキュー先頭の Docker 用ジョブを誤って拾ってしまう（ジョブのテレコ事故）。
  そのため、GitLab サーバー側でキューを完全に分離できるよう Runner（トークン）を `docker` と `shell` で 2 つに分離している
- **責務の分離**
  Lambda はタグ判定から `EXECUTOR` （ `docker` または `shell` ）のみを CodeBuild に渡し、Runner トークン（SSM パラメータ）の保持・解決は CodeBuild 側に集約している

### 3. なぜ自前 S3 バケットにオンデマンドキャッシュしているのか？

- **外部からの毎回ダウンロードの課題**
  約 50MB のバイナリを毎ビルド外部（GitLab 公式 S3: `us-east-1` ）からダウンロードすると、遅延や GitLab 側の障害・レート制限の影響を受ける
- **CodeBuild 標準キャッシュの制約**
  CodeBuild ではキャッシュ種別を 1 つしか選べず、標準 S3 キャッシュを使うと `LOCAL_DOCKER_LAYER_CACHE` （Docker レイヤーキャッシュ）が使えなくなる。
  また、tar 圧縮・解凍のオーバーヘッドがある。ローカルキャッシュ（ `LOCAL_CUSTOM_CACHE` ）もオンデマンド実行ではホスト破棄によりキャッシュミスしやすい
- **ECR カスタムイメージ（事前組み込み）の制約**
  CodeBuild 公式イメージ（ `aws/codebuild/standard:8.0` ）はホストフリートにキャッシュ済み（Pre-cached）で起動が数秒で終わるが、
  自前 ECR イメージにすると数 GB のイメージ pull が毎回発生して逆に 10〜30 秒以上遅くなる
- **自前 S3 キャッシュの採用**
  初回のみ外部から取得して S3 に保存し、2 回目以降は同一リージョンの S3 から生バイナリを直接取得することで、
  Docker レイヤーキャッシュを維持したまま数百ミリ秒でダウンロードを完了させている。GitLab のバージョンアップ時も `RUNNER_VERSION` に連動して自動更新される
