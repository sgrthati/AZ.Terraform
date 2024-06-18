output "lb_id" {
    value = one(azurerm_lb.lb[*].id)
}
output "lb_backend_pool_id" {
    value = one(azurerm_lb_backend_address_pool.backend-pool[*].id)
}