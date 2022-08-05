variable "allowed_ips" {
    type    = list
    default = []
}

variable "name" {
    type    = string
    default = "instawire"
}

variable "public_key" {
    type = string
}

variable "region" {
    type = string
}
