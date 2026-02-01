# MetalLB Module

## Purpose
Installs MetalLB to provide LoadBalancer functionality for clusters without a cloud provider, and applies an
IPAddressPool manifest for the configured address range.

## Variables
All variables are optional.
* `namespace` (default: `metallb-system`)
* `chart_version` (default: `~0.15.0`)
* `address_pool_cidr` (default: `192.168.60.11/30`)

## Example Usage
```hcl
module "metallb" {
  source = "../terraform-modules/metallb"
  # address_pool_cidr = "192.168.60.11/30"
}
```
