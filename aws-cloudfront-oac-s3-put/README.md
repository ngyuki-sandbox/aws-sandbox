# CloudFront OAC 経由で S3 へアップロード

```sh
export CLOUDFRONT_URL="$(terraform output -raw cloudfront_url)"

node index.ts
curl -s "$CLOUDFRONT_URL/test.txt"
xdg-open "$CLOUDFRONT_URL/sample.png"
```
