#module to create linux vm cluster,based on requirement you can disable by changing below variables
#we can add names variables here if we wanted created with that name
module "ProjectX" {
    source = "git::https://github.com/sgrthati/AZ.Terraform.git//modules/generic_resources/linux_vm?ref=main"
    resource_group_name = var.resource_group_name
    node_count = 2
    lb_enabled = true
    vm_pip_enabled = true
    dns_enabled = true
    dns_name = "internal.com"
}