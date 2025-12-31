output "instance_public_ips" {
  value = {
    for name, instance in oci_core_instance.instances :
    name => instance.public_ip if instance.public_ip != ""
  }
}

output "reserved_public_ip" {
  value = oci_core_public_ip.reserved_public_ip.ip_address
}
