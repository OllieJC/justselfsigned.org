resource "google_dns_record_set" "tlsa-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "_443._tcp.${var.domain}."
  type    = "TLSA"
  ttl     = "30"
  rrdatas = var.cert_sig
}

resource "google_dns_record_set" "udp-tlsa-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "_443._udp.${var.domain}."
  type    = "TLSA"
  ttl     = "30"
  rrdatas = var.cert_sig
}

resource "google_dns_record_set" "www-tlsa-cname-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "_443._tcp.www.${var.domain}."
  type    = "CNAME"
  ttl     = "30"
  rrdatas = ["_443._tcp.${var.domain}."]
}

resource "google_dns_record_set" "www-udp-tlsa-cname-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "_443._udp.www.${var.domain}."
  type    = "CNAME"
  ttl     = "30"
  rrdatas = ["_443._tcp.${var.domain}."]
}

resource "google_dns_record_set" "precert-tlsa-record" {
  count        = var.enable_precert_sign ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")

  name    = "tlsa._dane.${var.domain}."
  type    = "TLSA"
  ttl     = "30"
  rrdatas = [
    "3 0 1 ${chomp(var.precert_sig)}"
  ]
}
