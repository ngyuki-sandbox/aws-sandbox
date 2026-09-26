# CloudFormation StackSets による組織全体への配布

Organizations の管理アカウントから、すべてのメンバーアカウントに SSM Parameter を作成する Terraform サンプルです。

- 名前: `/sandbox/cfn-stackset/test`
- 型: `String`
- 値: `this is test`
- リージョン: 既定では `ap-northeast-1`

組織の Root を対象とするサービスマネージド型の StackSet を使用します。管理アカウント自身には作成されません。
自動デプロイを有効にしているため、後から組織に参加したアカウントにも作成されます。

## 信頼されたアクセスの有効化

管理アカウントで現在の状態を確認します。

```sh
aws cloudformation describe-organizations-access
```

`Status` が `DISABLED` の場合は、管理アカウントの管理者権限で有効化します。

```sh
aws cloudformation activate-organizations-access
aws cloudformation describe-organizations-access
```

`Status` が `ENABLED` になってから Terraform を適用してください。
信頼されたアクセスは組織共通の設定なので、このサンプルの Terraform では管理しません。

## 参考

- [StackSets を使用したアカウントとリージョン全体でのスタックの管理](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html)
- [StackSets の信頼されたアクセスの有効化](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-orgs-activate-trusted-access.html)
- [aws_cloudformation_stack_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set)
- [aws_cloudformation_stack_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_instances)
