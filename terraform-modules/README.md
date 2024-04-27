# Module List
## Cert-Manager
- This module when installed on a K8S cluster will generate requests for a SSL Certificate for all Ingresses on the cluster. A special annotation must be set for each of the Ingresses that need a certificate. For example, if using the LetsEncrypt certificate issuer, the annotation to add to the Ingress would look like
```
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```
## Ingress-Nginx
- The Ingress controller that can route HTTP requests coming in to the cluster based on either the Host or Path or a combination of both. The Ingress Controller exposes a K8S Service of type LoadBalancer which has an external IP exposed. All requests that come to this external IP will be received by the Ingress Controller and then forwarded to the correct Ingress based on the HTTP Host/Path information encapsulated in the request.

## MetalLB
- MetalLB is a load-balancer implementation that allows a Service of type LoadBalancer to have an external IP. This module is not being used currently, since the K3S cluster is shipped by default with Traefik which takes care of the load-balancing implementation as well as the ingress control.

## ArgoCD
- ArgoCD is being used to create subsequent applications on the cluster using ArgoCD release manifests and values.yaml files
