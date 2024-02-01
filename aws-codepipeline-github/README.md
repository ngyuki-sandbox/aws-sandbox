# github actions からプルリクをトリガーに aws codepipeline を実行

terraform apply で AWS 側の環境構築をします。
IAM Role の arn と CodePipeline の名前が出力されます。後で使います。
CodeStar Connections が保留中になるためマネコンで確定させます。

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
      - uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions
          aws-region: ap-northeast-1

      - run: aws sts get-caller-identity

      - run: aws codepipeline start-pipeline-execution
          --name ${{ secrets.CODEPIPELINE_NAME }}
          --source-revisions actionName=Source,revisionType=COMMIT_ID,revisionValue=${{ github.sha }}
          --variables name=PR_NUMBER,value=${{ github.event.number }} name=PR_ACTION,value=${{ github.event.action }}
```

GitHub で以下のシークレットを登録します。

```sh
gh secret set --app actions AWS_ROLE_ARN
gh secret set --app actions CODEPIPELINE_NAME
```

GitHub のリポジトリでプルリクを開くと CodePipeline が実行されます。

```sh
gh repo view -w
```
