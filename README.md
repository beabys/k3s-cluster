# k3s-cluster installations steps
create a new database and a new ha proxy using docker

### on master one
```bash
curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" sh -s - server --tls-san 10.27.10.50 --disable traefik --disable servicelb --disable local-storage
```
<!-- curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" sh -s - server --token=K10e8c170e82b51abf24c32dd51c0038f51b8904672a87724b71e59c57a020ff71c::server:375454f41509e83a3ee7cec2156013b7 --tls-san 10.27.10.50 --disable traefik --disable servicelb --disable local-storage -->
### get the token from master one
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```
### on the other masters
```bash
curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" sh -s - server --token=<token from master one> --tls-san 10.27.10.50 --disable traefik --disable servicelb --disable local-storage
```
#### good to know
- we disable traefik as we install using helm
- the service load balancer is disabled because we will use metallb to use the load balancer in our internal network
- local storage is disabled as we will use longhorn later

### on the agents
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://10.27.10.50:6443 sh -s - agent --token=<token from master one>
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
