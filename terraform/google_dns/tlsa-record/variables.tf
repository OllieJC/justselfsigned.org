variable "domain" {
  type = string
}

variable "cert_sig" {
  type = list
  default = []
}

variable "precert_sig" {
  type = string
}

variable "enable_precert_sign" {
  type = bool
  default = false
}
