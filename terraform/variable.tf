
# definimos la variable para el rg del acr
variable "rg_acr" {
  default = "acr_rg"
}

# esta variable la usaremos para todos los recources (VM,AKS,RG)
variable "location" {
    default ="uksouth"
  
}

#las siguientes variables tambien las usaremos para los direfentes resources
variable "vnet" {
  default = "prac2-vnet"
}

variable "subnet" {
  default = "prac2-subnet"
}

variable "nsg" {

  default = "prac2-nsg"
  
}

variable "rg_compute" {
  default = "compute"
  
}