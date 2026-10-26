
# default ネームスペース内のリソース参照権限を持つ Role
resource "kubernetes_role" "operator" {
  metadata {
    name      = "operator"
    namespace = "default"
  }

  rule {
    api_groups = ["", "apps"]
    resources  = ["pods", "services", "deployments"]
    verbs      = ["get", "list", "watch"]
  }
}

# hello:operators グループに Role を紐付ける RoleBinding
resource "kubernetes_role_binding" "operator" {
  metadata {
    name      = "operator"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.operator.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "hello:operators"
    api_group = "rbac.authorization.k8s.io"
  }
}
