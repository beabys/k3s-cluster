# First add metallb repository to your helm
```
helm repo add metallb https://metallb.github.io/metallb
```

# Check if it was found
```
helm search repo metallb
```

# Install metallb
```
helm upgrade --install metallb metallb/metallb -n metallb-system --create-namespace
```

# apply the service pool ip addresses
```
kubectl apply -f ./service-pool.yaml
```