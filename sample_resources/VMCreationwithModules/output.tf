output "Vnet" {
  
      value ={
          VNET_NAME = "${module.VNET.VNET_address_space}"
          PIP = "${module.VNET.VNET_PIP}"
          SUBNET = "${module.VNET.VNET_SN}"
          
          
      } 
 
}