output "reserved_public_ip" {
  value = oci_core_public_ip.reserved_public_ip.ip_address
}
