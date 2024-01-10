##################### Firewall ######################
resource "aws_networkfirewall_rule_group" "fw_standard_rg" {
  capacity = 100
  name     = "${var.owner}-standard-rulegroup"
  type     = "STATEFUL"
  
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "0.0.0.0/0"
          destination_port = 53
          direction        = "FORWARD"
          protocol         = "DNS"
          source           = var.core_vpc.cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = var.core_subnets["core"].cidr
          destination_port = 22
          direction        = "FORWARD"
          protocol         = "SSH"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = var.core_subnets["core"].cidr
          destination_port = 3389
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["3"]
        }
      }
    }

  }
  tags = {
    owner = var.owner
  }
}
resource "aws_networkfirewall_rule_group" "fw_domain_rg" {
  capacity = 100
  name     = "${var.owner}-domain-rulegroup"
  type     = "STATEFUL"
  
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.core_vpc.cidr, var.cdp_vpc.cidr]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = ["TLS_SNI"]
        targets = concat(var.fw_domain_ep, ["sts.${var.region}.amazonaws.com"])
      }
    }

  }
  tags = {
    owner = var.owner
  }
}

resource "aws_networkfirewall_rule_group" "fw_http_ep" {
  capacity = 100
  name     = "${var.owner}-http-rulegroup"
  type     = "STATEFUL"
  
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.core_vpc.cidr, var.cdp_vpc.cidr]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = ["HTTP_HOST"]
        targets = var.fw_http_ep
      }
    }

  }
  tags = {
    owner = var.owner
  }
}
resource "aws_networkfirewall_rule_group" "public" {
  capacity = 100
  name     = "${var.owner}-public-rulegroup"
  type     = "STATEFUL"
  
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.core_subnets["core"].cidr]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = ["TLS_SNI"]
        targets = ["www.google.com"]
      }
    }

  }
  tags = {
    owner = var.owner
  }
}
resource "aws_networkfirewall_firewall_policy" "fw" {
  name = "${var.fw_name}-policy"


  firewall_policy {
    stateful_default_actions = ["aws:drop_established"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      priority = 1
      resource_arn = aws_networkfirewall_rule_group.fw_standard_rg.arn
    }
    stateful_rule_group_reference {
      priority = 2
      resource_arn = aws_networkfirewall_rule_group.fw_domain_rg.arn
    }
    stateful_rule_group_reference {
      priority = 3
      resource_arn = aws_networkfirewall_rule_group.fw_http_ep.arn
    }
  }

  tags = {
    owner = var.owner
  }
}
resource "aws_networkfirewall_firewall" "fw" {
  name                = var.fw_name
  firewall_policy_arn = aws_networkfirewall_firewall_policy.fw.arn
  vpc_id              = aws_vpc.core.id
  subnet_mapping {
    subnet_id = aws_subnet.core["firewall"].id
  }

  tags = {
    owner = var.owner
  }
}
