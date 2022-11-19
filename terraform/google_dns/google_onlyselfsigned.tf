module "onlyselfsigned_web" {
  source                 = "./web-records"
  domain                 = "onlyselfsigned.org"
  ipv4s                  = var.a_ipv4s
  ipv6s                  = var.aaaa_ipv6s
}

module "onlyselfsigned_tlsa" {
  source                 = "./tlsa-record"
  domain                 = "onlyselfsigned.org"
  cert_sig               = var.cert_sig
  precert_sig            = var.precert_sig
}

module "onlyselfsigned_email" {
  source                 = "./email-records"
  domain                 = "onlyselfsigned.org"
  default_dmarc_record   = "v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s;fo=1;rua=mailto:onlyselfsigned.org-dmarc@olliejc.uk"
}

module "onlyselfsigned_caa" {
  source                 = "./caa-record"
  domain                 = "onlyselfsigned.org"
}
