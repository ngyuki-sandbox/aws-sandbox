# CodePipeline のソースに ECR を指定する

```sh
aws ecr get-login-password | docker login --username AWS --password-stdin "$(terraform output -raw ecr_repository_url)"

docker pull alpine:latest
docker tag alpine:latest "$(terraform output -raw ecr_repository_url):$(git log -1 --format=format:%h)"
docker push "$(terraform output -raw ecr_repository_url):$(git log -1 --format=format:%h)"
docker push "$(terraform output -raw ecr_repository_url):latest"
```

出力変数

```
ECR_IMAGE_DIGEST=sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0
ECR_IMAGE_TAG=latest
ECR_IMAGE_URI=999999999999.dkr.ecr.ap-northeast-1.amazonaws.com/sandbox@sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0
ECR_REGISTRY_ID=999999999999
ECR_REPOSITORY_NAME=sandbox
```

出力アーティファクト

```json
{
    "ImageSizeInBytes": "3410201",
    "ImageDigest": "sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0",
    "Version": "1.0",
    "ImagePushedAt": "Mon Mar 18 00:46:15 UTC 2024",
    "RegistryId": "999999999999",
    "RepositoryName": "sandbox",
    "ImageURI": "999999999999.dkr.ecr.ap-northeast-1.amazonaws.com/sandbox@sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0",
    "ImageTags": [
        "6e62bda",
        "latest"
    ]
}
```

## buildx

buildx で docker-container 使用時もトリガは実行される。

```sh
docker pull alpine:latest
docker buildx create --use
docker buildx build \
    --cache-to "mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=$(terraform output -raw ecr_repository_url):cache" \
    --tag "$(terraform output -raw ecr_repository_url):latest" \
    --push .
```

このとき ECR は次のようなよくわからない状態になるが・・

|  タグ  |   タイプ    | サイズ |
| :----- | :---------- | -----: |
| latest | Image Index | 3.41   |
|        | Image       | 0      |
|        | Image       | 3.41   |
| cache  | Other       | 3.41   |

後段には latest タグのついた Image Index の sha256 ダイジェストが渡される。
