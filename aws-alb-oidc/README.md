# ALB OIDC 認証検証

Application Load Balancer (ALB) の Google OAuth 2.0 OIDC 認証を検証する

## 事前準備

### 1. Google OAuth 2.0 クライアント ID の作成

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを選択または作成
3. 「API とサービス」→「認証情報」に移動
4. 「認証情報を作成」→「OAuth クライアント ID」を選択
5. アプリケーションの種類: **ウェブアプリケーション**
6. 承認済みのリダイレクト URI に以下を追加:
   ```
   https://<your-domain>/oauth2/idpresponse
   ```
7. Client ID と Client Secret を取得
8. `terraform.tfvars` ファイルを編集
