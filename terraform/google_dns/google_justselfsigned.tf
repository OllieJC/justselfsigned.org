module "justselfsigned_web" {
  source                 = "./web-records"
  domain                 = "justselfsigned.org"
  ipv4s                  = var.a_ipv4s
  ipv6s                  = var.aaaa_ipv6s
}

module "justselfsigned_tlsa" {
  source                 = "./tlsa-record"
  domain                 = "justselfsigned.org"
  cert_sig               = var.cert_sig
  precert_sig            = var.precert_sig
}

module "justselfsigned_email" {
  source                 = "./email-records"
  domain                 = "justselfsigned.org"
}

module "justselfsigned_caa" {
  source                 = "./caa-record"
  domain                 = "justselfsigned.org"
}
