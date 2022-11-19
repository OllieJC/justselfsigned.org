variable "domain" {
  type = string
}

variable "email_records" {
  type = bool
  default = true
}

variable "default_dmarc_record" {
  type = string
  default = "\"v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s;fo=1;rua=mailto:justselfsigned.org-dmarc@olliejc.uk\""
}

variable "additional_dmarc_ruas" {
  type = list
  default = []
}

variable "default_txt_record" {
  type = string
  default = "\"v=spf1 -all\""
}

variable "additional_txt_records" {
  type = list
  default = []
}
