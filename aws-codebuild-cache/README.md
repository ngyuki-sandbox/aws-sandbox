# CodeBuild のキャッシュの比較

- buildx で --push でプッシュすると ECR 上に 3 つのイメージが作られる？？
    - イメージそのものとイメージのインデックス、および application/vnd.in-toto+json なる署名関係のものらしい
    - ECR ライフライフサイクルではそれらそれぞれが 1 つとして数えられてしまうもよう
    - oci-mediatypes=true とか oci-mediatypes=false とかいろいろ変えてみても同じ
    - buildx で --load してから push すれば大丈夫そう
- LOCAL_DOCKER_LAYER_CACHE は機能している気がしない
    - 稀に CACHED になることがある？ 条件が良く判らない？ 運？
- buildx 外部キャッシュは効果あるけれども pull/push のオーバーヘッドがあるのでビルドが早いなら無くてもよさそう
- buildx create --use は builder 作成のオーバーヘッドが無視できない
    - 外部キャッシュを使うならともかくそうではないなら builder はデフォルトの docker のままがマシ

## あんちょこ

```sh
terraform -chdir=./terraform/ init
terraform -chdir=./terraform/ apply

export ECR_REPOSITORY_URL="$(terraform -chdir=./terraform/ output -raw ecr_repository_url)"
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR_REPOSITORY_URL"

cd ./deploy/

docker build --tag "$ECR_REPOSITORY_URL:latest" .
docker push "$ECR_REPOSITORY_URL:latest"

docker buildx build --load --tag "$ECR_REPOSITORY_URL:latest" .
docker push "$ECR_REPOSITORY_URL:latest"

docker buildx build --push --tag "$ECR_REPOSITORY_URL:latest" .
```
