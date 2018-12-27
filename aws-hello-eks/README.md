# Amazon Elastic Container Service for Kubernetes (EKS) を terraform で素振り

```sh
# kubectl と aws-iam-authenticator をインストール
curl -o ~/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/kubectl
curl -o ~/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator
chmod +x ~/bin/kubectl
chmod +x ~/bin/aws-iam-authenticator

# terraform.tfvars にキーペアと MyIPs を指定
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# クラスタを作成
terraform apply

# ~/.kube/config を設定
aws eks update-kubeconfig --name hello-eks

# Kubernetes へのアクセス確認
kubectl get svc

# aws-auth の ConfigMap を Kubernetes に反映
curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/aws-auth-cm.yaml
sed -i -e 's#rolearn:.*#rolearn: arn:aws:iam::999999999999:role/hello-eks-node#' aws-auth-cm.yaml
kubectl apply -f aws-auth-cm.yaml

# クラスタへのジョインを確認
kubectl get nodes

# Service と Deployment を作成
kubectl apply -f deploy.yaml

# Kubernetes に作成されたオブジェクト確認
kubectl get all

# ELB の DNS 名を表示
kubectl get service httpd -o json | jq '.status.loadBalancer.ingress[].hostname' -r

# ELB 確認
curl -i xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-999999999.ap-northeast-1.elb.amazonaws.com
```

## 後始末

```sh
# Service と Deployment を削除
kubectl delete -f deploy.yaml

# 削除の確認
kubectl get all

# クラスタの削除
terraform destroy -auto-approve
```

## 注意事項

IAM でソースアドレス制限していると Launch Configuration が作成できない。
