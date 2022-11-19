module "selfsigned_web" {
  source                 = "./web-records"
  domain                 = "self-signed.org"
  ipv4s                  = var.a_ipv4s
  ipv6s                  = var.aaaa_ipv6s
}

module "selfsigned_tlsa" {
  source                 = "./tlsa-record"
  domain                 = "self-signed.org"
  cert_sig               = var.cert_sig
  existing_sig           = var.existing_sig
  precert_sig            = var.precert_sig

}

module "selfsigned_email" {
  source                 = "./email-records"
  domain                 = "self-signed.org"
  default_dmarc_record   = "\"v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s;fo=1;rua=mailto:self-signed.org-dmarc@olliejc.uk\""
}

module "selfsigned_caa" {
  source                 = "./caa-record"
  domain                 = "self-signed.org"
}
