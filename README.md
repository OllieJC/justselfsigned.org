# justselfsigned.org

[justselfsigned.org](https://justselfsigned.org) is an example site with recommendations for the adoption of more decentralisation in the HTTPS trust system.

In summary, user agents should trust SSCs (Self-Signed Certificates) with DNS Security Extensions (DNSSEC) and DANE (DNS-based Authentication of Named Entities).

A user agent is any browser, client or HTTP library; for example, [Mozilla Firefox](https://www.mozilla.org/en-GB/firefox/new/), [curl](https://curl.se/), or [python httpx](https://www.python-httpx.org/).

[COLLAPSE_START]: <> (Ideal Configuration)

Ideally, user agents should additionally trust websites with the following configuration:

- fully-trusted DNSSEC domain name
- have an SSC with only valid public domains
- all domain names in an SSC have valid TLSA DNS records with signatures that match the SSC
- SSCs have less than a 90-day expiry
- inclusion in CT (Certificate Transparency) logs with associated SSPC(s) (Self-Signed Pre-Certificate)

[COLLAPSE_END]: <> ()

[COLLAPSE_START]: <> (CT log changes)

Unfortunately, existing CT logs do not support SSCs due to spam concerns ([rfc6962](https://www.rfc-editor.org/rfc/rfc6962)).
The suggestion (being raised in [rfc9162](https://datatracker.ietf.org/doc/html/rfc9162)) is for CT logs to check for full DNSSEC compliance and TLSA records when generating a CT log entry for SSCs, which would work in the following way:

<ol>
  <li>a new SSPC (Self-Signed Pre-Certificate) is generated with the following:</li>
  <ul><li>only valid domains</li><li>less than 90-day expiry (although this may start in the future)</li></ul>
  <li>the SSPC signature is added to <code>tlsa._dane</code> TLSA record for every domain</li>
  <li>SSPC is submitted to a CT log</li>
  <li>CT log checks for valid domains and associated TLSA signatures and issues an SCT (Signed Certificate Timestamp)</li>
  <li>SSC (Self-Signed Certificates) is generated from the SSPC to include the SCT</li>
  <li>SSC signature is added to TLSA records (likely replacing the pre-certificate signature)</li>
  <li>SSC is submitted to the CT log</li>
  <li>CT log checks for valid domains, associated TLSA records and a valid SCT</li>
</ol>

Additionally, CT logs could use SSCs, where they would add their SSPC and SSC to their own log. The client adding the first SSPC and SSC (of the CT log itself) to the CT log would not check CT logs during the initial creation of the CT log.

[COLLAPSE_END]: <> ()

[COLLAPSE_START]: <> (Current Certificates)

These are the current certificates in use by the site:

- [sspc.pem](https://justselfsigned.org/sspc.pem)
- [ssc.pem](https://justselfsigned.org/ssc.pem)

[COLLAPSE_END]: <> ()
