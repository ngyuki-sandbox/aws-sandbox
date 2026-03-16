# ALB JWT 検証

Application Load Balancer (ALB) の JWT 検証

## 事前準備

auth0 の アプリケーション -> API で Auth0 Management API を選択する
テストタブのレスポンスの access_token が JWT です
issuer は https://www.jwt.io/ で JWT をデコードして確認する

```sh
read -x token
curl "$(terraform output -raw alb_url)" -H  "authorization: Bearer $token"
```
