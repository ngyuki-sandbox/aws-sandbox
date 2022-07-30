# [AWS][Terraform]Terraform だけで Auto Scaling を使わずに EC2 を Rolling update や Blue-Green Deployment

## はじめに

Terraform はこういったデプロイのための専用のツールでは無いので、より適切なツールを使う方が良い（CodeDeploy とか）。
そうではなくとも、Terraform で `aws_instance` リソースを直接作るよりは Auto Scaling を使う方が良い。

以上がわかったうえで、あえて Terraform だけででやってみます。

## Rolling update

一時的にインスタンスの数が単純に倍になっているので全然ローリングはしていません。

Terraform は基本的にリソースをリプレースするとき削除→作成するため、AMI を更新するためにインスタンスが作り直される際に一旦すべてのインスタンスを削除したうえで新しいインスタンスが作成されます。

この動作は Terraform の `lifecycle.create_before_destroy` で変更できます。これを true にすると、リソースを作り直す際、新しいリソースを作ってから、その作成が完了した後に、古いリソースが削除されます。

> https://www.terraform.io/language/meta-arguments/lifecycle#create_before_destroy

`aws_instance` と `aws_lb_target_group_attachment` にこれを設定してやれば、AMI の更新によりインスタンスがリプレースされる際、新しいインスタンスが作成＆ターゲットグループにアタッチされた後、古いインスタンスが削除されるので大丈夫・・・と思いきや、これだけでは不十分です。

`aws_instance` はインスタンスが作成さえされればその中身がどうであろうと Terraform 的には完了したことになるし、`aws_lb_target_group_attachment` もアタッチできさえすればヘルスチェックが終わってなくても Terraform 的には完了したことになります。

インスタンスが作成された直後でまだ起動中の状態、そしてターゲットグループにアタッチされてからまだ最初のヘルスチェックが終わっていない状態で、古いインスタンスが削除されてしまうと 503 Service Unavailable です。

これでは都合が悪いので `aws_lb_target_group_attachment` のプロビジョナーで `aws elbv2 wait target-in-service` を使ってインスタンスが healthy になるまで待機させます。

```js
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this.id

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -ex -o pipefail
      if [ "$wait" -ne 0 ]; then
        timeout "$wait" aws --region "$region" elbv2 wait target-in-service \
          --target-group-arn "$target_group_arn" \
          --targets "Id=$target_id"
      fi
    EOF
    environment = {
      wait = var.wait
      region = data.aws_region.current.name
      target_group_arn = self.target_group_arn
      target_id = self.target_id
    }
  }
}
```

変数 `wait` でタイムアウト時間が指定できます。0 を指定すれば待機しません。

```sh
# 最大で 300 秒待機する
terraform apply -v wait=300

# 待機しない
terraform apply -v wait=0
```

なお、Terraform の AWS Provider で `profile` を指定している場合、プロビジョナの aws cli でも同じものを指定するのを忘れないようにしてください。

## Blue-Green Deployment

インスタンスだけではなくターゲットグループも新しいものを作成し、一通りインスタンスが healthy になった時点で ALB のリスナーのデフォルトアクションを変えるようにしてみます。

まず、AMI が変わったときにターゲットグループをリプレースさせる必要があります。EC2 インスタンスは AMI が変われば勝手にリプレースされますが、ターゲットグループは AMI 関係ないので、次のようにAMI が変わったときにターゲットグループの名前が変わるようにして、無理やり関係させます。

```js
resource "aws_lb_target_group" "this" {
  name     = substr(format("%s-%s", local.name, sha256(local.ami_id)), 0, 32)

  // ...snip...
}
```

そしてターゲットグループの `create_before_destroy` を設定したうえで、プロビジョナで `aws elbv2 wait target-in-service` を使ってターゲットグループが InService になるのを待機します。引数で `--targets` の省略すれば、ターゲットグループにぶら下がるすべてのインスタンスが healthy になるのを待機します。

```js
resource "aws_lb_target_group" "web" {
  name     = substr(format("%s-%s", local.name, sha256(local.ami_id)), 0, 32)

  // ...snip...

  provisioner "local-exec" {
    command = <<-EOF
      set -ex -o pipefail
      if [ "$wait" -ne 0 ]; then
        timeout "$wait" aws --region "$region" elbv2 wait target-in-service --target-group-arn "$target_group_arn"
      fi
    EOF
    environment = {
      wait = var.wait
      region = data.aws_region.current.name
      target_group_arn = self.arn
    }
  }
}
```

はい、この方法はうまくいきません。

このプロビジョナが存在することにより Terraform 的にはターゲットグループが InService になるまでターゲットグループの作成が終わったことにならなくなります。ターゲットグループの作成が終わらないことにはそのターゲットグループへインスタンスをアタッチすることもできません。もちろん、ターゲットグループへインスタンスをアタッチしないことには InService には決してなりません。つまりデッドロックしています。

また、ターゲットグループは ALB のリスナーのアクションにアタッチされていないとヘルスチェックが実行されません。もちろん、Terraform 的にはターゲットグループの作成が完了するまではリスナーにアタッチすることもできないため、いつまでもヘルスチェックは開始されません。さらにデッドロックしています。

これらを解決するために `null_resource` を使います。

```js
resource "null_resource" "web" {
  triggers = {
    target_group_arn = aws_lb_target_group.web.arn
  }
  provisioner "local-exec" {
    command = <<-EOF
      set -ex -o pipefail
      if [ "$wait" -ne 0 ]; then
        timeout "$wait" aws --region "$region" elbv2 wait target-in-service --target-group-arn "$target_group_arn"
      fi
    EOF
    environment = {
      wait = var.wait
      region = data.aws_region.current.name
      target_group_arn = aws_lb_target_group.web.arn
    }
  }
}
```

`aws_lb_target_group` の方にはプロビジョナは記述しません。

さらに、本来のリスナーとは別にダミーのリスナーを設けて、本来のリスナーは `null_resource` を、ダミーのリスナーは `aws_lb_target_group` を、それぞれデフォルトアクションに指定します。

```js
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    target_group_arn = null_resource.web.triggers.target_group_arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "dummy" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 8080

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

これで AMI の更新時に次の順番でデプロイされるようになります。

- 新しいターゲットグループとインスタンスが作成され、アタッチされる
- ダミーのリスナーのデフォルトアクション先が新しいターゲットグループに変更される
- 新しいターゲットグループが InService になるのを待機する
- 新しいターゲットグループが InService になった
- 本来のリスナーのデフォルトアクション先が新しいターゲットグループに変更される
- 古いターゲットグループとインスタンスが削除される

## さいごに

Terraform はこういったデプロイのための専用のツールでは無いので、より適切なツールを使う方が良い（CodeDeploy とか）。
そうではなくとも、Terraform で `aws_instance` リソースを直接作るよりは Auto Scaling を使う方が良い。
