```
helm upgrade --install loki grafana/loki-stack  --values ./values.yaml -n grafana-loki --create-namespace
```

add the ingress controller

```
kubectl apply -f loki-ingress-controller.yml
```

if want to expose loki in the LB
```
kubectl patch svc loki -n grafana-loki -p '{"spec": {"type": "ClusterIP"}}'
```