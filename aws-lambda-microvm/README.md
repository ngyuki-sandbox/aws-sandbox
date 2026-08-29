# AWS Lambda MicroVMs

```sh
terraform init
terraform apply

aws lambda-microvms run-microvm \
    --image-identifier "$(terraform output -raw microvm_image_arn)" \
    --execution-role-arn "$(terraform output -raw iam_role_arn)" \
    --ingress-network-connectors "arn:aws:lambda:ap-northeast-1:aws:network-connector:aws-network-connector:HTTP_INGRESS" \
        "arn:aws:lambda:ap-northeast-1:aws:network-connector:aws-network-connector:SHELL_INGRESS" \
    --idle-policy '{"autoResumeEnabled":true,"maxIdleDurationSeconds":900,"suspendedDurationSeconds":300}' \
| tee tmp/microvm.json

aws lambda-microvms create-microvm-auth-token \
    --microvm-identifier "$(jq .microvmId -r < tmp/microvm.json)" \
    --expiration-in-minutes 30 \
    --allowed-ports '[{"allPorts":{}}]' \
    --query 'authToken|["X-aws-proxy-auth"]' --output text \
> tmp/token.txt

curl -H "X-aws-proxy-auth: $(cat tmp/token.txt)" "https://$(jq .endpoint < tmp/microvm.json -r)/"
```

## クリーンアップ

```sh
aws lambda-microvms list-microvms | jq -r '.items[]|select(.state!="TERMINATED").microvmId' \
| xargs -P0 -t -i aws lambda-microvms terminate-microvm --microvm-identifier {}
```

## メモ

**ビルドとスナップショット**

MicroVM イメージの作成時、Dockerfile のビルドだけではなく、一度実行されて ready になった状態のスナップショットが保持される。
その後の実行時にはスナップショットからの復元となるため爆速で起動する。

> https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/microvms-images-snapshots.html

一意性の問題は注意が必要かもしれない。

**IAM Role**

`awscc_lambda_microvm_image` の `build_role_arn` の IAM Role はあくまでもビルド時のロール。
ランタイムのロールは `run-microvm` で指定する必要がある。指定しないとログが出ない。

**更新のトリガ**

S3 に新しいアーカイブをアップロードしただけでは新しいバージョンがビルドされない。

> https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/microvms-images.html#microvms-images-updating

環境変数や説明にアーカイブのハッシュなどを入れればアーカイブの更新の都度ビルドさせることができる。

**ライフサイクルフック**

ライフサイクルフックはすべて無効にもできる。
ただ ready や validate を無効にするといつの時点のスナップショットが保存されるかが不定になる。

**シェルアクセス**

ドキュメントにはシェルトークンを利用した CLI によるシェルアクセスの記述があるが、そのシェルトークンをどう使うかの記述がなさそう。
ctr コマンドが記載されているが、それをどこでどう使うのか不明（MicroVM のホスト側にアクセスする術がある？）。

> https://docs.aws.amazon.com/lambda/latest/dg/microvms-troubleshooting.html#microvms-troubleshooting-shell

`SHELL_INGRESS` を有効にするだけでマネコンは普通にアクセスできる。

# 参考

- https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-microvms-guide.html
- https://github.com/hashicorp/terraform-provider-aws/issues/48526
- https://github.com/hashicorp/terraform-provider-awscc/releases/tag/v1.90.0
