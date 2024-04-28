# CodeBuild を GitHub Actions の self-hosted runner に設定

- https://docs.aws.amazon.com/codebuild/latest/userguide/action-runner.html

## メモ

- CodeBuild と GitHub Actions で OAuth 接続されていないと WehHook の登録でコケる
    - AWS 側で WehHook 登録すると GitHub 側にも自動で登録されるもよう
    - `https://github.com/$ORG/$REPO/settings/hooks`
- CodeBuild の GitHub への OAuth 接続は CodeStar Connections とは別物
    - CodeStar Connections は GitHub App なのでもっときめ細かいアクセス制御が可能
    - OAuth 接続だと org 単位で許可しかできなさそう？
    - しかも AWS アカウント+リージョンごとに1つしか設定できない
        - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_source_credential
    - 1つの AWS アカウントで複数の GitHub Org を跨るような運用はできない

## GitHub Actions

```yaml
name: codebuild-hosted
on:
  - push
jobs:
    test:
    runs-on: codebuild-sandbox-${{ github.run_id }}-${{ github.run_attempt }}
    steps:
      - run: aws sts get-caller-identity
      - uses: actions/checkout@v4
      - run: ls -l
      - uses: actions/setup-node@v4
      - run: node --version
      - run: npm --version
```
