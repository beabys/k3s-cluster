# k3s-cluster installations steps
create a new database and a new ha proxy using docker

### on master one
```bash
curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://user:pass@tcp(ip:port)/db' K3S_KUBECONFIG_MODE="644" sh -s - server --tls-san <ip of the loadbalance (haproxy)> --disable traefik --disable servicelb --disable local-storage
```
### get the token from master one
```bash
cat /var/lib/rancher/k3s/server/node-token
```
### on the other masters
```bash
curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://user:pass@tcp(ip:port)/db' K3S_KUBECONFIG_MODE="644" sh -s - server --token=<token from master one> --tls-san <ip of the loadbalance (haproxy)> --disable traefik --disable servicelb --disable local-storage
```
#### good to know
- we disable traefik as we install using helm
- the service load balancer is disabled because we will use metallb to use the load balancer in our internal network
- local storage is disabled as we will use longhorn later

### on the agents
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://10.27.10.50:6443 sh -s - agent --token=K101c176295e5e4170740c47488fe8ed9bc5ef7f1688582c06d42766e48f87cbf01::server:44d9d557a708f71a4d7ebcf91370a9a8
```

### get yaml file
```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

### sugested to do it in the following order:

- [ ] traefik
- [ ] metallb
- [ ] longhorn
- [ ] prometheus
- [ ] loki
- [ ] argo-cd
- [ ] keyclock
