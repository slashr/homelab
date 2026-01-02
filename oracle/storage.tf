# Object Storage for Velero backups
# Uses OCI's S3-compatible API for Velero to store Kubernetes PVC backups

# Get Object Storage namespace (required for bucket creation)
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

# Bucket for Velero backups
resource "oci_objectstorage_bucket" "velero_backups" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "homelab-velero-backups"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
}

# Customer Secret Key for S3-compatible API access
# This creates credentials that work with AWS S3 SDKs/tools
resource "oci_identity_customer_secret_key" "velero_s3" {
  display_name = "velero-backup"
  user_id      = var.user_ocid
}

# Outputs for configuring Velero
output "velero_s3_endpoint" {
  description = "S3-compatible endpoint for Velero"
  value       = "${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.${var.oci_region}.oraclecloud.com"
}

output "velero_s3_access_key" {
  description = "S3 access key for Velero"
  value       = oci_identity_customer_secret_key.velero_s3.id
  sensitive   = true
}

output "velero_s3_secret_key" {
  description = "S3 secret key for Velero"
  value       = oci_identity_customer_secret_key.velero_s3.key
  sensitive   = true
}

output "velero_bucket_name" {
  description = "Bucket name for Velero backups"
  value       = oci_objectstorage_bucket.velero_backups.name
}
