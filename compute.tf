resource "oci_core_instance" "amd1" {

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "amd1"

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys,
    #user_data = filebase64("${path.module}/scripts/init.sh")
  }

  create_vnic_details {
    assign_public_ip          = false
    subnet_id                 = oci_core_subnet.public_subnet.id
    assign_private_dns_record = true
    private_ip                = "10.0.0.10"
    hostname_label            = "amd1"
  }

  source_details {
    #Required
    source_id   = var.amd_source_image_id
    source_type = "image"
  }
}

resource "oci_core_instance" "amd2" {

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "amd2"

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys,
    #user_data = filebase64("${path.module}/scripts/init.sh")
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.public_subnet.id
    assign_private_dns_record = true
    private_ip                = "10.0.0.20"
    hostname_label            = "amd2"
  }

  source_details {
    #Required
    source_id   = var.amd_source_image_id
    source_type = "image"
  }
}

resource "oci_core_instance" "arm1" {

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "arm1"

  shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys,
    #user_data = filebase64("${path.module}/scripts/init.sh")
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.public_subnet.id
    assign_private_dns_record = true
    private_ip                = "10.0.0.30"
    hostname_label            = "arm1"
  }

  source_details {
    #Required
    source_id   = var.ampere_source_image_id
    source_type = "image"
  }
}

resource "oci_core_instance" "arm2" {

  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "arm2"

  shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys,
    #user_data = filebase64("${path.module}/scripts/init.sh")
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.public_subnet.id
    assign_private_dns_record = true
    private_ip                = "10.0.0.40"
    hostname_label            = "arm2"
  }

  source_details {
    #Required
    source_id   = var.ampere_source_image_id
    source_type = "image"
  }
}
