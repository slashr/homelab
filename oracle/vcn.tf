resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id

  cidr_blocks  = ["10.0.0.0/16"]
  display_name = "vcn"
  dns_label    = "vcn"
}


resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id

  display_name = "Default Security List"

  egress_security_rules {
    protocol    = "all" // TCP
    description = "Allow all outbound traffic"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol    = "all"
    description = "Allow inbound traffic from subnet"
    source      = "10.0.0.0/16"
  }

  ingress_security_rules {
    protocol    = "17"
    description = "Allow Wireguard traffic"
    udp_options {
      min = 51820
      max = 51820
    }
    source = "0.0.0.0/0"
  }

  dynamic "ingress_security_rules" {
    for_each = local.tcp_rules
    content {
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.value.description
      tcp_options {
        min = ingress_security_rules.value.port_min
        max = ingress_security_rules.value.port_max
      }
      source = ingress_security_rules.value.source
    }
  }

}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = true
}

resource "oci_core_default_route_table" "route_table" {
  compartment_id             = var.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn.id
  cidr_block        = oci_core_vcn.vcn.cidr_blocks[0]
  display_name      = "public_subnet"
  dns_label         = "subnet"
  security_list_ids = [oci_core_vcn.vcn.default_security_list_id]
}
