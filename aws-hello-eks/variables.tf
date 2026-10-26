
variable "name" {
  type        = string
  default     = "hello-eks"
  description = "EKS クラスター名"
}

variable "k8s_version" {
  type        = string
  default     = "1.31"
  description = "Kubernetes バージョン"
}
