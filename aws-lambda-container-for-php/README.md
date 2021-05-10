# Lambda container image for PHP

## Deploy to lambda

```sh
terraform init
terraform apply -target aws_ecr_repository.php

aws ecr --region ap-northeast-1 get-login-password |
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com"

IMAGE_REPO="$ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/lambda-container-for-php-php"
DOCKER_TAG=latest
docker build -t "$IMAGE_REPO:$DOCKER_TAG" .
docker push "$IMAGE_REPO:$DOCKER_TAG"

terraform apply -var "docker_tag=$DOCKER_TAG"

aws lambda invoke \
  --function-name lambda-container-for-php-func \
  --invocation-type RequestResponse \
  --cli-binary-format raw-in-base64-out \
  --payload '{"hello":"php"}' \
  /dev/stderr > /dev/null
#=> {"statusCode":200,"headers":{"Content-Type":"text/plain","x-php-version":"8.0.6"},"body":{"payload":{"hello":"php"}}}
```

## Run local docker

```sh
wget https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie
chmod +x ./aws-lambda-rie

docker build -t lambda-container-for-php-local .
docker run --rm -p 8080:8080 -v "$PWD/aws-lambda-rie:/aws-lambda-rie:ro" --entrypoint /aws-lambda-rie lambda-container-for-php-local bin/bootstrap handlers/index.php

curl -XPOST "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"hello":"php"}'
#=> {"statusCode":200,"headers":{"Content-Type":"text/plain","x-php-version":"8.0.6"},"body":{"payload":{"hello":"php"}}}
```
