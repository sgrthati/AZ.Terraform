output "aks_config" { 
    sensitive = true
    value = azurerm_kubernetes_cluster.aks.kube_config 
    }

# Required to set access policy on key vault.
output "aks_agentpool_object_id" { 
    value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id 
    }

# Required when setting up csi driver secret provier class.
output "aks_agentpool_client_id" { 
    value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id 
    }

# Required to set IAM role on appgw subnet.
output "aks_appgw_object_id" { 
    value = [azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id]
    }