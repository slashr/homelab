# MetalLB Module

## Purpose
Installs MetalLB to provide LoadBalancer functionality for clusters without a cloud provider.

## Required Variables
This module has no required variables.

## Example Usage
```hcl
module "metallb" {
  source = "../terraform-modules/metallb"
}
```
