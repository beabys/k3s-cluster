# k3s-cluster installations steps
create a new database and a new ha proxy using docker

## Create node or lxc for db and ha proxy
### HA proxy
```
services:
  k3slb:
    image: haproxy
    ports:
      - "6443:6443"
    restart: always
    volumes:
      - ./config:/usr/local/etc/haproxy
    deploy:
      resources:
        limits:
          memory: 2g
    mem_limit: 2g
    memswap_limit: 2g
```

### ha proxy config
```
frontend k3s-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend k3s-backend

backend k3s-backend
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s
    server k3sm1 10.27.10.51:6443 check
    server k3sm2 10.27.10.52:6443 check
```

### Mariadb or mysql
```
services:
  k3s-db:
    image: mariadb:latest
    container_name: k3s-db
    restart: always
    environment:
      MYSQL_DATABASE: k3sdb
      MYSQL_USER: k3s
      MYSQL_PASSWORD: k3spass
      MYSQL_ROOT_PASSWORD: k3spass
    volumes:
      - ./data/mysql:/var/lib/mysql
    ports:
      - "3306:3306"
    deploy:
      resources:
        limits:
          memory: 2g
        reservations:
          memory: 1g
    # Tell MariaDB to restrict its buffer pool to ~70% of the limit
    command: --innodb-buffer-pool-size=1434M
```

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
