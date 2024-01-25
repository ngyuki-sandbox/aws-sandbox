# github actions からプルリクをトリガーに aws codepipeline を実行

terraform apply で AWS 側の環境構築をします。
CodeStar Connections のためにマネコンで追加の作業が必要かも？
IAM Role の arn と CodePipeline の名前が出力されます。後で使います。

GitHub 側のリポジトリで次のようなワークフローを作成します。

```yaml
name: codepipeline
on:
  pull_request:
    branches:
      - main
jobs:
  codepipeline:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
          aws-region: ap-northeast-1

      - name: aws sts get-caller-identity
        run: aws sts get-caller-identity

      - name: aws codepipeline start-pipeline-execution
        run: aws codepipeline start-pipeline-execution
          --name ${{ secrets.CODEPIPELINE_NAME }}
          --source-revisions actionName=Source,revisionType=COMMIT_ID,revisionValue=${{ github.sha }}
```

GitHub で以下のシークレットを登録します。

- AWS_ROLE_ARN
- CODEPIPELINE_NAME

GitHub のリポジトリでプルリクを開くと CodePipeline が実行されます。
