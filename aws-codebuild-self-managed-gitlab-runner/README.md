# CodeBuild を Self-managed な Gitlab の Self-managed な runner に設定

- https://aws.amazon.com/jp/about-aws/whats-new/2025/02/aws-codebuild-managed-runners-gitlab-self-managed/

## メモ

- CodeConnections の「ホスト」と「接続」は terraform で登録後に保留中になるのでマネコンで操作が必要
    - ホストは GitLab のパーソナルアクセストークンが必要
    - ホストが利用可能になっていれば接続はポチポチ押すだけ
- aws_codeconnections_connection が AWS リソースタグを変更するだけで provider_type が known after apply で replaced になる
    - replace されると保留中に戻ってしまうので非常に不便
    - provider_type を ignore_changes に指定すれば大丈夫そう
- aws_codebuild_project で CodeConnections の arn が指定できないので terraform でサクッとは作成できない
    - https://github.com/hashicorp/terraform-provider-aws/issues/38572
    - local-exec とかでごにょごにょする必要あり
- CodeBuild 内で shell executor として実行されるので .gitlab-ci.yml の image とかは無視される
    - CodeBuild 内で dockerd が利用可能ではあるが既存の docker executor な runner からサクッと移行はできなさそう
