##################### Firewall ######################
resource "aws_networkfirewall_rule_group" "fw_rg" {
  capacity = 100
  name     = "${var.owner}-statefulgroup"
  type     = "STATEFUL"
  rule_group {
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
          destination      = aws_instance.core-jump.private_ip
          destination_port = 22
          direction        = "FORWARD"
          protocol         = "SSH"
          source           = "0.0.0.0/0"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
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
    stateless_default_actions          = ["aws:drop"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.fw_rg.arn
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
