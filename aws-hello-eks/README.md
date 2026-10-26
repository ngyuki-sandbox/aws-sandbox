# Amazon EKS を Terraform で素振り

Amazon EKS クラスターおよび Amazon Linux 2023 ベースのマネージドノードグループを Terraform で構築・検証するサンプルです。

## 手順

```sh
# クラスタ構築
terraform init
terraform apply

# ~/.kube/config を設定
aws eks update-kubeconfig --name "$(terraform output -raw cluster_name)"

# current-context 確認
kubectl config current-context

# ノードの参加確認
kubectl get nodes

# Service と Deployment を作成
kubectl apply -f deploy.yaml

# 作成されたリソースの確認
kubectl get all

# 接続確認（プロビジョニング完了まで数分かかる場合があります）
curl -i "http://$(kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

## IAM ロールと Kubernetes RBAC によるきめ細かなアクセス制御の検証

本構成では、AWS IAM ロールと Kubernetes の RBAC を連携させたアクセス制御を検証できます。
EKS Access Entry で IAM ロールに対して Kubernetes グループ名（`hello:operators`）を紐付け、Kubernetes 側の `Role` + `RoleBinding` でそのグループに対して `default` ネームスペースの限定的な権限（`pods`, `services`, `deployments` に対する `get`, `list`, `watch`）のみを付与しています。

この検証用クライアントとして、該当 IAM ロールがアタッチされた EC2 インスタンス（`operator`）を用意しており、SSM Session Manager 経由で接続して限定権限の動作を確認できます。

```sh
# EC2 インスタンス ID を取得して接続
aws ssm start-session --target "$(terraform output -raw operator_instance_id)"

# EKS クラスターの設定を取得
aws eks update-kubeconfig --name hello-eks

# 許可されているリソースの閲覧（成功する）
kubectl get pods
kubectl get services
kubectl get deployments

# 許可されていないリソースの閲覧（権限エラーで拒否される）
kubectl get nodes

# 許可されていないリソース作成操作（権限エラーで拒否される）
kubectl run test-pod --image=nginx
```

## ELB とセキュリティグループの自動連携の仕組み

Kubernetes 標準の Service（`type: LoadBalancer`）をデプロイすると、Kubernetes の service-controller（in-tree AWS クラウドプロバイダー）が裏側で AWS リソースとセキュリティグループを以下のように動的に自動管理します。

- ELB 用セキュリティグループの自動生成:
    - `k8s-elb-<hash>` というセキュリティグループが自動作成され、Service で指定されたポート（例: 80）に対して `0.0.0.0/0`（全開放）からのインバウンド通信が許可されます
- ワーカーノード側セキュリティグループへのルール自動追加:
    - ワーカーノードにアタッチされているセキュリティグループの中から、`kubernetes.io/cluster/<cluster-name>` タグが付与されたセキュリティグループを自動検出します
        - 本構成では EKS が自動作成したクラスターセキュリティグループです
    - そのセキュリティグループに対し、上記 ELB 用セキュリティグループからの NodePort（30000〜32767）宛てのインバウンド許可ルールが動的に自動追加されます
- ターゲットインスタンスの自動登録:
    - ワーカーノード（EC2 インスタンス）を自動検出し、ELB の登録済みインスタンス（ターゲット）として自動登録します

## 注意事項（外部公開方式について）

- 本サンプルでの構成:
  - 本リポジトリでは素振りの手軽さを優先し、Kubernetes 標準の Service（`type: LoadBalancer`）を用いて直接ロードバランサー（Classic Load Balancer）を作成・公開しています
  - パブリックサブネットには、Kubernetes がロードバランサーの配置先を自動検出するための `kubernetes.io/role/elb = "1"` タグを付与しています
- 実運用での一般的な構成:
  - 実運用や本番環境では、クラスター内に **AWS Load Balancer Controller** などの Ingress Controller を導入し、`Ingress` リソース経由で Application Load Balancer（ALB）を作成して公開する構成が一般的です
  - Ingress を利用することで、パスベース・ホストベースのルーティングや、単一 ALB の複数サービス間での共有（コスト削減）、ACM 証明書による TLS/SSL 終端などを柔軟に管理できます

## 後始末

```sh
# マニフェストの削除
kubectl delete -f deploy.yaml

# 削除確認（ロードバランサーが消えたことを確認）
kubectl get all

# クラスターの削除
terraform destroy
```

### 後始末の注意事項（重要）

- **ロードバランサーの自動削除は行われません**:
    - `deploy.yaml` の Service（`type: LoadBalancer`）によって作成されるロードバランサーやセキュリティグループは、Kubernetes が AWS 上に動的にプロビジョニングしたリソースであり、Terraform の管理外（`tfstate` 外）です
- **クラスター削除前に必ずマニフェストを削除してください**:
    - マニフェストを削除せずに `terraform destroy` を実行すると、サブネット内にロードバランサーや ENI、セキュリティグループが残存しているため、VPC やサブネットの削除に失敗（依存関係エラー）します
    - 先にクラスターが削除されてしまうと `kubectl` からの削除も行えなくなり、AWS マネジメントコンソール等から手動でロードバランサーやセキュリティグループを削除する必要があります
    - そのため、必ず先に `kubectl delete -f deploy.yaml` を実行し、AWS 上からロードバランサーが完全に消えたことを確認してから `terraform destroy` を実行してください
