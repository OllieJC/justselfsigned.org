locals {
  default_tags   = {
    "Service" : "justselfsigned.org",
    "Reference" : "https://github.com/OllieJC/justselfsigned.org",
  }

  extra_low_ttl  = 30
  low_ttl        = 30 # 300
  standard_ttl   = 30 # 3600
  long_ttl       = 30 # 86400
}

variable "cert_sig" {
  type = list
}

variable "precert_sig" {
  type = string
  default = ""
}

variable "enable_precert_sign" {
  type = bool
  default = false
}

variable "a_ipv4s" {
  type = list
}

variable "aaaa_ipv6s" {
  type = list
}
