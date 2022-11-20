resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id

  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn"
  dns_label      = "vcn"
}

# Fetches the private IP of the Wireguard OCI instance
data "oci_core_private_ips" "wireguard_private_ip" {
  ip_address = oci_core_instance.amd1.private_ip
  subnet_id  = oci_core_subnet.public_subnet.id
}

resource "oci_core_public_ip" "reserved_public_ip" {
    #Required
    compartment_id = var.compartment_id
    lifetime = "RESERVED"
    display_name = "Groundhog"
    # This basically binds the reserved public IP with the private IP belonging to the wireguard instance
    private_ip_id = data.oci_core_private_ips.wireguard_private_ip.private_ips[0]["id"]
    lifecycle {
      prevent_destroy = true
    }
}

resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id

  display_name  = "Default Security List"

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
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow SSH traffic"
  tcp_options {
    min = 22
    max = 22
  }
  source      = "0.0.0.0/0"
  }


  ingress_security_rules {
  protocol    = "6"
  description = "Allow SSH port-forwarding traffic"
  tcp_options {
    min = 2244
    max = 2244
  }
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow HTTP traffic"
  tcp_options {
    min = 80
    max = 80
  }
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow HTTPS traffic"
  tcp_options {
    min = 443
    max = 443
  }
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow K3S API traffic"
  tcp_options {
    min = 6443
    max = 6443
  }
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow MicroK8S API traffic"
  tcp_options {
    min = 16443
    max = 16443
  }
  source      = "0.0.0.0/0"
  }

  ingress_security_rules {
  protocol    = "6"
  description = "Allow K8S NodePort traffic"
  tcp_options {
    min = 30000
    max = 32767
  }
  source      = "0.0.0.0/0"
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

