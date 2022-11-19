resource "google_dns_record_set" "caa" {
  name         = "${var.domain}."
  managed_zone = replace(var.domain, ".", "-")
  type         = "CAA"
  ttl          = 30

  rrdatas = [
    "0 issue \";\"",
    "0 issuewild \";\"",
    "0 iodef \"mailto:${var.domain}-caa@olliejc.uk\""
  ]
}
