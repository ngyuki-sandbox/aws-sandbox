# CodeBuild のキャッシュの比較

- https://aws.amazon.com/jp/blogs/containers/announcing-remote-cache-support-in-amazon-ecr-for-buildkit-clients/
- https://docs.docker.com/build/cache/backends/registry/

## メモ

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

## Quick Start

```sh
terraform -chdir=./terraform/ init
terraform -chdir=./terraform/ apply

export ECR_REPOSITORY_URL="$(terraform -chdir=./terraform/ output -raw ecr_repository_url)"
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR_REPOSITORY_URL"

docker build --tag "$ECR_REPOSITORY_URL:latest" ./deploy/
docker push "$ECR_REPOSITORY_URL:latest"

docker buildx build --load --tag "$ECR_REPOSITORY_URL:latest" ./deploy/
docker push "$ECR_REPOSITORY_URL:latest"

docker buildx build --push --tag "$ECR_REPOSITORY_URL:latest" ./deploy/

docker buildx create --use
docker buildx build --load --tag "$ECR_REPOSITORY_URL:latest" \
  --cache-from "type=registry,ref=$ECR_REPOSITORY_URL:cache" \
  --cache-to "mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=$ECR_REPOSITORY_URL:cache" \
  ./deploy/
```

## ビルドドライバーを docker-container にする必要ある？

`--cache-to` でリモートキャッシュを使用する場合は

`docker buildx create --use` などでビルドドライバーを `docker-container` に変更しないとコケる。

```
ERROR: Cache export feature is currently not supported for docker driver. Please switch to a different driver (eg. "docker buildx create --use")
```

参考の AWS ブログで `docker build` だけになっているのは、例えば GitHub Actions などであれば
[setup-buildx-action](https://github.com/docker/setup-buildx-action) でビルドドライバー＆環境変数がセットアップされるため。
