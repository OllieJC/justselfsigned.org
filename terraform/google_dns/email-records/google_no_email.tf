resource "google_dns_record_set" "spf-record" {
  count        = var.email_records ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")
  name         = "${var.domain}."
  type         = "TXT"
  ttl          = "60"
  rrdatas      = length(var.additional_txt_records) > 0 ? concat([var.default_txt_record], var.additional_txt_records) : [var.default_txt_record]
}

resource "google_dns_record_set" "dmarc-record" {
  count        = var.email_records ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")
  name    = "_dmarc.${var.domain}."
  type    = "TXT"
  ttl     = "60"
  rrdatas = [
    length(var.additional_dmarc_ruas) > 0 ? join(",mailto:", concat([var.default_dmarc_record], var.additional_dmarc_ruas)) : var.default_dmarc_record
  ]
}

resource "google_dns_record_set" "null-mx-record" {
  count        = var.email_records ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")
  name    = "${var.domain}."
  type    = "MX"
  ttl     = "60"
  rrdatas = ["0 ."]
}

resource "google_dns_record_set" "dkim-record" {
  count        = var.email_records ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")
  name    = "*._domainkey.${var.domain}."
  type    = "TXT"
  ttl     = "60"
  rrdatas = ["\"v=DKIM1; p=\""]
}

resource "google_dns_record_set" "dkim-signing-required-record" {
  count        = var.email_records ? 1 : 0
  managed_zone = replace(var.domain, ".", "-")
  name    = "_domainkey.${var.domain}."
  type    = "TXT"
  ttl     = "60"
  rrdatas = ["o=-"]
}
