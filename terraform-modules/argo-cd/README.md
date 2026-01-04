# Argo CD Module

## Purpose

Installs Argo CD and an application set to bootstrap other resources on the Kubernetes cluster.

## Required Variables

This module has no required variables.

## Example Usage

```hcl
module "argo-cd" {
  source     = "../terraform-modules/argo-cd"
  depends_on = [module.cert-manager]
}
```
