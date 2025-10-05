locals {
  instances = {
    amd1 = {
      shape               = "VM.Standard.E2.1.Micro"
      memory_in_gbs       = 1
      ocpus               = 1
      private_ip          = "10.0.0.10"
      assign_public_ip    = false
      source_image_id     = var.amd_source_image_id
    }
    amd2 = {
      shape               = "VM.Standard.E2.1.Micro"
      memory_in_gbs       = 1
      ocpus               = 1
      private_ip          = "10.0.0.20"
      assign_public_ip    = true
      source_image_id     = var.amd_source_image_id
    }
    arm1 = {
      shape               = "VM.Standard.A1.Flex"
      memory_in_gbs       = 12
      ocpus               = 2
      private_ip          = "10.0.0.30"
      assign_public_ip    = true
      source_image_id     = var.ampere_source_image_id
    }
    arm2 = {
      shape               = "VM.Standard.A1.Flex"
      memory_in_gbs       = 12
      ocpus               = 2
      private_ip          = "10.0.0.40"
      assign_public_ip    = true
      source_image_id     = var.ampere_source_image_id
    }
  }
}

# State migration: map old individual resources to new for_each structure
moved {
  from = oci_core_instance.amd1
  to   = oci_core_instance.instances["amd1"]
}

moved {
  from = oci_core_instance.amd2
  to   = oci_core_instance.instances["amd2"]
}

moved {
  from = oci_core_instance.arm1
  to   = oci_core_instance.instances["arm1"]
}

moved {
  from = oci_core_instance.arm2
  to   = oci_core_instance.instances["arm2"]
}

resource "oci_core_instance" "instances" {
  for_each = local.instances

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = each.value.shape
  display_name        = each.key

  shape_config {
    memory_in_gbs = each.value.memory_in_gbs
    ocpus         = each.value.ocpus
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  create_vnic_details {
    assign_public_ip          = each.value.assign_public_ip
    subnet_id                 = oci_core_subnet.public_subnet.id
    assign_private_dns_record = true
    private_ip                = each.value.private_ip
    hostname_label            = each.key
  }

  source_details {
    source_id   = each.value.source_image_id
    source_type = "image"
  }
}
