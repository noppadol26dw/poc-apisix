resource "aws_wafv2_ip_set" "cloudfront_ips" {
  name               = "${var.project_name}-${var.environment}-cloudfront-ips"
  description        = "IP set for CloudFront"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_wafv2_regex_pattern_set" "rate_limit_pattern" {
  name               = "${var.project_name}-${var.environment}-rate-limit-pattern"
  description        = "Pattern for rate limiting"
  scope              = "CLOUDFRONT"
  regular_expression = ".*"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_wafv2_rule_group" "owasp" {
  name        = "${var.project_name}-${var.environment}-owasp"
  description = "OWASP Top 10 rule group"
  scope       = "CLOUDFRONT"
  capacity    = 500
  vendor      = "AWSManagedRules"

  managed_rule_group_statement {
    name        = "AWSManagedRulesCommonRuleSet"
    vendor_name = "AWS"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_wafv2_ip_set_reference_statement" "rate_limit" {
  ip_set_reference_statement {
    arn = aws_wafv2_ip_set.cloudfront_ips.arn
  }
  action {
    block {}
  }
}

resource "aws_wafv2_regex_pattern_set_reference_statement" "rate_limit_regex" {
  regex_pattern_set_reference_statement {
    arn = aws_wafv2_regex_pattern_set.rate_limit_pattern.arn
    text_transformation {
      priority = 0
      type     = "NONE"
    }
  }
  action {
    block {}
  }
}

resource "aws_wafv2_rate_based_statement" "rate_limit" {
  aggregate_key = "IP"
  limit         = 2000

  scope_down_statement {
    statement {
      rate_based_statement {
        aggregate_key = "IP"
        limit         = 2000
      }
    }
  }

  action {
    block {}
  }
}

resource "aws_wafv2_rule_group" "custom" {
  name        = "${var.project_name}-${var.environment}-custom-rules"
  description = "Custom rate limiting rule group"
  scope       = "CLOUDFRONT"
  capacity    = 100
  vendor      = "AWS"

  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        aggregate_key = "IP"
        limit         = 2000
        scope_down_statement {
          statement {
            regex_match_statement {
              regex_string_set_reference_statement {
                arn = aws_wafv2_regex_pattern_set.rate_limit_pattern.arn
              }
              field_to_match {
                single_header {
                  name = "X-Forwarded-For"
                }
              }
            }
          }
        }
      }
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-${var.environment}-web-acl"
  description = "WAF Web ACL for APISIX"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }

  rule {
    name     = "OWASPRules"
    priority = 1
    override_action {
      none {}
    }
    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.owasp.arn
      }
    }
    visibility_config {
      sampled_requests_enabled   = false
      cloudwatch_metrics_enabled = true
      metric_name                = "OWASPRules"
    }
  }

  rule {
    name     = "CustomRateLimit"
    priority = 2
    override_action {
      none {}
    }
    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.custom.arn
      }
    }
    visibility_config {
      sampled_requests_enabled   = false
      cloudwatch_metrics_enabled = true
      metric_name                = "CustomRateLimit"
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl_association" "cloudfront" {
  web_acl_arn  = aws_wafv2_web_acl.main.arn
  resource_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"

  depends_on = [
    aws_wafv2_web_acl.main
  ]
}

data "aws_caller_identity" "current" {}
