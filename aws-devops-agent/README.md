# DevOps Agent

- [AWS DevOps Agent とは](https://docs.aws.amazon.com/ja_jp/devopsagent/latest/userguide/about-aws-devops-agent.html)

## IAM Role

- `DevOpsAgentRole-AgentSpace`
    - DevOps Agent が AWS リソースを調査・分析するためのロール
    - `AIDevOpsAgentAccessPolicy`
        - AWS リソースの調査・分析に必要な読み取り系権限が中心
        - `Get*`/`List*`/`Describe*` など
        - `cloudtrail:StartQuery` や `support:CreateCase` など、一部の書き込み操作も含む
- `DevOpsAgentActionsRole-AgentSpace`
    - DevOps Agent がオペレーターに承認された変更を AWS リソースへ実行するためのロール
    - この検証では、対象の EC2 インスタンスに対する `ec2:RebootInstances` だけを inline policy で許可している
    - AWS managed policy の `AIDevOpsAgentActionsPolicy` を使用すると、IAM、Organizations、SSO、STS などを原則除外した広範な変更権限を付与できる
- `DevOpsAgentRole-WebappAdmin`
    - オペレーターが DevOps Agent Web App から Agent Space を操作するためのロール
    - `AIDevOpsOperatorAppAccessPolicy`
        - Agent Space を操作する権限
    - IAM 認証では、trust policy で `sts:AssumeRole` と `sts:TagSession` を許可する
    - IAM Identity Center で Trusted Identity Propagation を使用する場合は、`sts:SetContext` の許可も必要
- `DevOpsAgentChannel`
    - `AIDevOpsChannelAccessPolicy`
    - Slack などのチャネルから Agent Space の chat を利用するためのロール
    - IAM Identity Center のユーザー identity をチャネルから伝播する場合は、Trusted Identity Propagation 用の `sts:SetContext` を trust policy に追加する

## エージェントアクション

- [What's new](https://docs.aws.amazon.com/devopsagent/latest/userguide/whats-new.html)
- [Working with directed actions](https://docs.aws.amazon.com/devopsagent/latest/userguide/working-with-devops-agent-working-with-directed-actions.html)

Directed Actions は 2026-08-25 に追加された機能で、古い AWS CLI や AWSCC provider では必要な項目を扱えない。

2026-09-22 時点では、AWS CLI を `2.36.2` から `2.36.49` へ更新すると、Directed Actions に必要な API を利用できた。
一方、AWSCC provider `v1.102.0` では、Agent Space の `preferences` と AWS association の `agentElevatedRoleArn` を設定できなかった。

この検証では、Terraform の `terraform_data` と `local-exec` から AWS CLI を呼び出し、Directed Actions の有効化と Actions Role の登録を行っている。

## トポロジ

- [What is a DevOps Agent Topology?](https://docs.aws.amazon.com/devopsagent/latest/userguide/about-aws-devops-agent-what-is-a-devops-agent-topology.html)

DevOps Agent は、CloudFormation と AWS Resource Explorer の 2 つの方法で AWS リソースを検出する。

- CloudFormation で構築したリソースは stack 単位で検出され、トポロジの Container view では stack がコンテナとして表示される
- CloudFormation を使用せずに構築したリソースは、AWS Resource Explorer からタグ付きリソースとして検出される
    - 対象アカウントで AWS Resource Explorer を有効にしておく必要がある
- Terraform の state や module は DevOps Agent から直接参照されないため、Terraform 固有の構成単位はそのままではトポロジに反映されない
- Terraform で共通の `Project` タグなどを付けることで、リソース間の関係や application boundary の判定に利用されることが期待できる

## Slack との接続

- [Connecting Slack](https://docs.aws.amazon.com/devopsagent/latest/userguide/connecting-to-ticketing-and-chat-connecting-slack.html)

### 接続

- `DevOpsAgentChannel` ロールは Terraform であらかじめ作成できる
- Slack workspace の登録には OAuth による認可が必要なため、この検証では AWS Management Console から接続した
- public channel と private channel のどちらにも一方向の通知を送信できる
- DevOps Agent との双方向通信を有効にできるのは private channel だけ

### Chat 履歴

この検証では、Slack でのやり取りを Agent Space の Web App から確認できなかった。`aws devops-agent list-chats` を実行しても、Slack で開始した chat は表示されなかった。

`ListChats` は認証された session のユーザー identity に基づいて chat を取得するため、Slack と Web App で異なる identity が使用されていることが原因と考えられる。IAM Identity Center と Trusted Identity Propagation を使用して identity を揃えた場合の挙動は未確認。

### Directed Actions

Slack から EC2 インスタンスの reboot を指示すると、承認が必要であることは通知されたものの、reboot は実行されなかった。一方、Web App では承認画面が表示され、承認後に reboot が実行された。

Slack integration では Directed Actions の承認操作を完了できない可能性があるが、失敗の原因は未確認。
