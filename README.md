# git-to-ops

## Install ArgoCD
```sh
cd argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-cd argo/argo-cd -n argo-cd --create-namespace --values=values.yaml
```
## Oracle Free Tier
2 AMD Instances 1 CPU/1GB RAM/50GB Boot Volume each: VM.Standard.E2.1.Micro
4 ARM Instances 1 OCPU/6GB RAM/50GB Boot Volume each: VM.Standard.A1.Flex

### Notes
- ARM instances will not have always free tag as they are flexible shape.
- ARM instances will be deleted after one-month trial. They have to be then recreated

