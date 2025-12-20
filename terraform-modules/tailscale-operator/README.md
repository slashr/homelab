# Tailscale Operator

Terraform module to deploy the [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator).

## Prerequisites

Before using this module, configure your Tailscale account:

1. Add ACL tags to your tailnet policy:

   ```json
   "tagOwners": {
     "tag:k8s-operator": [],
     "tag:k8s": ["tag:k8s-operator"]
   }
   ```

2. Create an OAuth client in the [Tailscale admin console](https://login.tailscale.com/admin/settings/oauth):
   * Scopes: `Devices Core`, `Auth Keys`, `Services` (write)
   * Tag: `tag:k8s-operator`

3. Enable HTTPS and MagicDNS in [DNS settings](https://login.tailscale.com/admin/dns).

## Usage

```hcl
module "tailscale-operator" {
  source              = "../terraform-modules/tailscale-operator"
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}
```

## Exposing Services

Once deployed, expose services via Tailscale ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: my-service
      port:
        number: 80
  tls:
    - hosts:
        - my-service
```

The service will be available at `https://my-service.<tailnet>.ts.net`.
