# GitHub のプルリクをトリガーに CodePipeline V2 を実行する

## プルリクエストのトリガーのブランチの includes と excludes

```sh
# dev -> main : 実行される
# fix -> dev  : 実行されない
excludes = ["dev"]
```

```sh
# dev -> main : 実行されない
# fix -> dev  : 実行される
includes = ["dev"]
```

つまりプルリクエストのトリガーでのブランチのフィルターはプルリクエストのベースブランチ（ターゲットブランチ）に効く。
