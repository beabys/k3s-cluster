helm

```
helm upgrade --install -f ./values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

adding ingress controller
```
kubectl apply -f alert-manager-ingress-controller.yml && \
kubectl apply -f grafana-ingress-controller.yml && \
kubectl apply -f prometheus-ingress-controller.yml
```

example custom serviceMonitor
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rpc-app-service-monitor #monitor name
  namespace: monitoring #namespace of the monitoring
  labels:
    app: rpc-app
    release: prometheus
spec:
  namespaceSelector:
    matchNames:
    - example #name space where app is deployed
  selector:
    matchLabels:
      app: rpc-app
  endpoints:
  - port: web #name of the service port
```