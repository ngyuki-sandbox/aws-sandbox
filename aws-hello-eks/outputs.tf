
output "cluster_name" {
  description = "EKS クラスター名"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "EKS コントロールプレーンのエンドポイント"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "Kubernetes バージョン"
  value       = aws_eks_cluster.cluster.version
}

output "operator_instance_id" {
  description = "作業用 EC2 インスタンスの ID"
  value       = aws_instance.operator.id
}
