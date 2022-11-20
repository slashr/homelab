data "oci_identity_availability_domains" "availability_domains" {
  #Required
  compartment_id = var.compartment_id
}

