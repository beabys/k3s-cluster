# First add traefik repository to your helm
```
helm repo add traefik https://traefik.github.io/charts
```

# update helm
```
helm repo update
```

# Install traefik
```
helm install traefik traefik/traefik -n traefik  --create-namespace
```
