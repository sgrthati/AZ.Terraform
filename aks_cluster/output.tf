output "kube_config" {
  description = "Kube config"
  value       = module.aks.kube_config
  sensitive = true
}

output "host" {
  description = "Kube host"
  value       = module.aks.host
  sensitive = true
}