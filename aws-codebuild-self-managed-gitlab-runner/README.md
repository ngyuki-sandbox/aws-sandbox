# CodeBuild を Self-managed な Gitlab の Self-managed な runner に設定

- https://aws.amazon.com/jp/about-aws/whats-new/2025/02/aws-codebuild-managed-runners-gitlab-self-managed/

## 初回セットアップ手順

CodeConnections の「ホスト」および「接続」は作成直後に保留中（`PENDING`）ステータスとなるため、初回の `terraform apply` は CodeBuild プロジェクト作成の段階で失敗する。
以下の流れで GitLab と AWS マネジメントコンソールでの手動認証を行ってから、再度 `terraform apply` を実行する。

1. 初回 `terraform apply` を実行
   - ホストと接続のリソースが作成された後、接続が未完了のため途中で失敗する
2. GitLab 側で PAT を発行
   - 管理者アカウントの Personal Access Token（PAT）が必要
   - スコープ: `api`（GitLab で Admin Mode が有効な場合は `admin_mode` も必要）
   - ホスト初期登録時のハンドシェイクにのみ使用され AWS 側には保存されないため、有効期限は最短（1 日など）でよく、セットアップ完了後は削除してよい
3. AWS マネジメントコンソール側で認証
   - ホストのセットアップ: CodeConnections の画面で作成されたホストを選択し、「ホストのセットアップ」から GitLab の PAT を入力して `Available` にする
   - 接続のセットアップ: 作成された接続を選択し、「保留中の接続を更新」から接続を `Available` にする
4. （任意）GitLab 側で OAuth アプリケーション名を変更
   - ホストのセットアップ時に GitLab の「Admin area > Applications（`/admin/applications`）」へ `AWS Connector for GitLab Self-Managed` という固定名でアプリが自動登録される
   - 複数作成した際に判別がつかなくなるため、Edit からわかりやすい名前に変更しておくとよい（表示名を変更しても動作には影響しない）
5. 再度 `terraform apply` を実行
   - 接続が `Available` になっているため、残りの CodeBuild プロジェクトや Webhook が正常に作成される

## .gitlab-ci.yml の設定例

CodeBuild でホストされる GitLab Runner でジョブを実行するには、`tags` に `codebuild-<project-name>-$CI_PROJECT_ID-$CI_PIPELINE_IID-$CI_JOB_NAME` を指定する。

```yaml
stages:
  - build

build-job:
  stage: build
  script:
    - echo "Hello from CodeBuild Runner!"
  tags:
    - codebuild-<project-name>-$CI_PROJECT_ID-$CI_PIPELINE_IID-$CI_JOB_NAME
```

`<project-name>` には Terraform で作成した CodeBuild プロジェクト名（`var.name`）を指定する。
末尾の `$CI_PROJECT_ID-$CI_PIPELINE_IID-$CI_JOB_NAME` は、ジョブを CodeBuild のビルド実行に正しくマッピングし、パイプラインのキャンセル時にビルドを停止するために必須。

### イメージやインスタンスサイズのオーバーライド

タグを追加することで、CodeBuild プロジェクト側の設定を上書きすることも可能。

```yaml
build-job:
  stage: build
  script:
    - echo "Hello from custom runner!"
  tags:
    - codebuild-<project-name>-$CI_PROJECT_ID-$CI_PIPELINE_IID-$CI_JOB_NAME
    - image:arm-3.0
    - instance-size:small
```

詳細や指定可能な値は以下を参照。

- https://docs.aws.amazon.com/codebuild/latest/userguide/gitlab-runners-update-labels.html
- https://docs.aws.amazon.com/codebuild/latest/userguide/sample-gitlab-runners-gitlab-ci.images.html

## メモ

- CodeConnections の「ホスト」と「接続」は terraform で登録後に保留中になるのでマネコンで操作が必要
    - ホストは GitLab のパーソナルアクセストークンが必要
    - ホストが利用可能になっていれば接続はポチポチ押すだけ
- aws_codeconnections_connection が AWS リソースタグを変更するだけで provider_type が known after apply で replaced になる
    - replace されると保留中に戻ってしまうので非常に不便
    - provider_type を ignore_changes に指定すれば大丈夫そう
- CodeBuild 内で shell executor として実行されるので .gitlab-ci.yml の image とかは無視される
    - CodeBuild 内で dockerd が利用可能ではあるが既存の docker executor な runner からサクッと移行はできなさそう
