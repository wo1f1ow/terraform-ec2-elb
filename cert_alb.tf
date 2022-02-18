# This data source looks up the public DNS zone
data "aws_route53_zone" "public" {
  name         = var.domain
  private_zone = false
}


# This creates an SSL certificate
resource "aws_acm_certificate" "wwwdomain" {
  domain_name       = aws_route53_record.wwwdomain.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# This is a DNS record for the ACM certificate validation to prove we own the domain
#
# This example, we make an assumption that the certificate is for a single domain name so can just use the first value of the
# domain_validation_options.  It allows the terraform to apply without having to be targeted.
# This is somewhat less complex than the example at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
# - that above example, won't apply without targeting

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.wwwdomain.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.wwwdomain.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.wwwdomain.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "wwwdomain" {
  certificate_arn         = aws_acm_certificate.wwwdomain.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}

# Standard route53 DNS record for "wwwdomain" pointing to an ALB
resource "aws_route53_record" "wwwdomain" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "${var.domain}"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}

output "testing" {
  value = "Test this demo code by going to https://${aws_route53_record.wwwdomain.fqdn} and checking your have a valid SSL cert"
}