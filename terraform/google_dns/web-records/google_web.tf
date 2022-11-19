resource "google_dns_record_set" "a-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "${var.domain}."
  type    = "A"
  ttl     = "30"
  rrdatas = var.ipv4s
}

resource "google_dns_record_set" "www-a-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "www.${var.domain}."
  type    = "A"
  ttl     = "30"
  rrdatas = var.ipv4s
}

resource "google_dns_record_set" "aaaa-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "${var.domain}."
  type    = "AAAA"
  ttl     = "30"
  rrdatas = var.ipv6s
}

resource "google_dns_record_set" "www-aaaa-record" {
  managed_zone = replace(var.domain, ".", "-")
  name    = "www.${var.domain}."
  type    = "AAAA"
  ttl     = "30"
  rrdatas = var.ipv6s
}
