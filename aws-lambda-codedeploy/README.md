# Lambda with codedeploy

## デプロイ

```sh
terraform init
terraform apply -target aws_ecr_repository.main
aws ecr get-login-password | docker login --username AWS --password-stdin "$(terraform output -raw ecr_repository_url)"

export IMAGE_REPO="$(terraform output -raw ecr_repository_url)"
export VERSION="$(date +v%Y%m%dT%H%M%S)"
docker build -t "$IMAGE_REPO" --build-arg "VERSION=$VERSION" .
docker push "$IMAGE_REPO"

aws lambda invoke \
--function-name "$(terraform output -raw lambda_function_name):latest" \
--invocation-type RequestResponse \
--cli-binary-format raw-in-base64-out \
--payload '{"hello":"world"}' \
/dev/stderr > /dev/null
```

## CodeDeploy を使う？

Lambda 関数のバージョン付けは CodeBuild などで自前でやる必要があり、
そのバージョン間のトラフィックコントロールを CodeDeploy がやってくれるだけ。
トラフィックコントロールが必要無いなら CodeDeploy を使うまでもないと思う。
