# aws-codebuild-gitlab-docker-runner

> - https://x.com/ngyuki/status/1895882545356816430
> - https://x.com/ngyuki/status/1896168997693120865

CodeBuild で素では shell executor しか実行できないので、自前で wehbook を仕込むことで、次の経路で docker executor を実行する例。

- Gitlab wehbook -> lambda -> codebuild -> gitlab-runner

terraform gitlab provider を使うために terraform 実行時に GITLAB_TOKEN を環境変数に入れておく必要があります。

```sh
export GITLAB_TOKEN=abc123...
```

本来の CodeBuild Gitlab Self-managed Runner ではタグが `codebuild-<codebuild>-$CI_PROJECT_ID-$CI_PIPELINE_IID-$CI_JOB_NAME` のような形式で、
実行ごとに Runner が登録 → 削除されていますが、試しに事前に Runner を登録しておいたうえで要求に応じて CodeBuild で gitlab-runner を実行するだけにしてみたところ、大丈夫そうなのでそのようにしています（AWS が敢えてそうしていないということはなにか理由があるかもしれない）。

なお、pending になった Job の tag_list を得るためだけに Gitlab API を呼ぶために terraform で project token を作成していますが、有効期限が最大 365 日なので定期的に terraform apply してトークンのローテートが必要です(https://x.com/ngyuki/status/1896168999471534437)。
