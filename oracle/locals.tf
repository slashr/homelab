locals {

  tcp_rules = [
    {
      protocol    = "6"
      description = "Allow SSH traffic"
      port_min    = 22
      port_max    = 22
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Custom application port 1100"
      port_min    = 1100
      port_max    = 1100
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Custom application port 1101"
      port_min    = 1101
      port_max    = 1101
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Custom application port 1102"
      port_min    = 1102
      port_max    = 1102
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Allow HTTP traffic"
      port_min    = 80
      port_max    = 80
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Allow HTTPS traffic"
      port_min    = 443
      port_max    = 443
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Allow K3S API traffic"
      port_min    = 6443
      port_max    = 6443
      source      = "0.0.0.0/0"
    },
    {
      protocol    = "6"
      description = "Allow K8S NodePort traffic"
      port_min    = 30000
      port_max    = 32767
      source      = "0.0.0.0/0"
    }
  ]
}
