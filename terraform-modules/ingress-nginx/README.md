# Ingress NGINX Module

## Purpose
Deploys the Kubernetes Ingress NGINX controller to route HTTP/HTTPS traffic within the cluster.

## Required Variables
This module has no required variables.

## Example Usage
```hcl
module "ingress-nginx" {
  source = "../terraform-modules/ingress-nginx"
}
```
