# Terraform Modules

## Module Index

| Module | Description | Path |
| --- | --- | --- |
| Cert-Manager | Issue TLS certs via Let's Encrypt with Cloudflare DNS01 | `terraform-modules/cert-manager` |
| External-DNS | Sync Kubernetes DNS records to Cloudflare | `terraform-modules/external-dns` |
| Argo CD | GitOps controller and app-of-apps bootstrap | `terraform-modules/argo-cd` |
| Ingress-Nginx | Optional ingress controller for HTTP(S) | `terraform-modules/ingress-nginx` |
| MetalLB | Optional bare-metal load balancer | `terraform-modules/metallb` |

## Cert-Manager

Installs cert-manager and provisions a production Let's Encrypt ClusterIssuer for TLS certificates. Ingress resources
must include an annotation such as:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

## External-DNS

Installs ExternalDNS to publish service and ingress DNS records to Cloudflare using a scoped API token.

## Ingress-Nginx

Optional ingress controller that routes HTTP(S) traffic based on host/path rules. Exposes a LoadBalancer service with an
external IP and forwards requests to the correct ingress definition.

## MetalLB

Optional load balancer implementation that assigns external IPs to `LoadBalancer` services when running on bare metal.
Not used by default because k3s ships with Traefik for ingress and load balancing.

## Argo CD

Installs Argo CD to manage application deployments via GitOps (app-of-apps pattern) and coordinates install order with
cert-manager and ExternalDNS dependencies.
