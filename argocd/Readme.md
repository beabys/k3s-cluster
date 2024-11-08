
# add the helm repo argo-cd
```
helm repo add argo-cd https://argoproj.github.io/argo-helm
```
# update helm
```
helm repo update
```

# Install argo-cd
```
helm upgrade --install argo-cd argo-cd/argo-cd  --values ./argocd/values.yaml -n argo-cd --create-namespace
```

## using old method
### create namespace
```
kubectl create ns argocd
```
### apply yaml file
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### patch the service to be a loadbalancer
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer", "loadBalancerIP": "10.27.10.62"}}'
```