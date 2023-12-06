# CloudFront

## Cache-Control

### public

- キャッシュが TTL 内なら
    - CF はキャッシュを応答する
- レスポンスに ETag が含まれるならリクエストは If-None-Match 付き
    - オリジンが 200 → Miss from cloudfront
    - オリジンが 304 → RefreshHit from cloudfront

### must-revalidate

- キャッシュが TTL 内なら
    - CF はキャッシュを応答する
- レスポンスに ETag が含まれるならリクエストは If-None-Match 付き
    - オリジンが 200 → Miss from cloudfront
    - オリジンが 304 → RefreshHit from cloudfront

### no-cache

- TTL とは無関係に CF->オリジン のリクエストは行われる
- レスポンスに ETag が含まれるならリクエストは If-None-Match 付き
    - オリジンが 200 → Miss from cloudfront
    - オリジンが 304 → RefreshHit from cloudfront

### private

- TTL とは無関係に CF->オリジン のリクエストは行われる
- レスポンスに ETag が含まれていてもリクエストは If-None-Match 無しになる
- 常に Miss from cloudfront となる

### no-store

- TTL とは無関係に CF->オリジン のリクエストは行われる
- レスポンスに ETag が含まれていてもリクエストは If-None-Match 無しになる
- 常に Miss from cloudfront となる

## メモ

- private と no-store は CDN に於いては同じ
    - キャッシュ無効な場合は両方指定されていることが多いけど no-store だけで十分
- no-cache で、キャッシュするが常に検証、が実現できる
    - max-age=0,must-revalidate と同じ
    - どこでキャッシュ可能かの指定のために private や public と併用する
- must-revalidate はオリジン切断時に再検証が必要かどうか
    - 未指定だとオリジン切断時に期限切れキャッシュが返されることがある
    - 指定しておくとオリジン切断時にキャッシュが期限切れなら 50x とかになる
    - はずなのだけど CloudFront だとそうならない気がする・・？
    - stale-if-error=0 で指定すれば大丈夫
- リクエストポリシーを指定すると If-None-Match 付きリクエストが送られなくなる？
    - 特別な理由がない限り指定しないのが無難？？
