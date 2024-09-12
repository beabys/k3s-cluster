# k3s-cluster


#   # curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.60:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server --disable traefik --disable servicelb" sh -
#     # curl -sfL https://get.k3s.io | sh -s - server --tls-san 10.27.10.60 --disable traefik --disable servicelb

# # on master 1
# export K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb'
# export K3S_KUBECONFIG_MODE="644"
# curl -sfL https://get.k3s.io | sh -s - server --tls-san 10.27.10.60 --disable traefik --disable servicelb --disable local-storage
#
# on the other masters
# export K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.60:3306)/k3sdb' && export K3S_KUBECONFIG_MODE="644"
# curl -sfL https://get.k3s.io | sh -s - server --token=K1026372b95441be2b520a4d911115ef6c2bcada744ca9cf5149506208939969fe2::server:3c497c1e1d8e4ab18ef75deca0d16355 --tls-san 10.27.10.60 --disable traefik --disable servicelb --disable local-storage

# try this one
# curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" sh -s - server --tls-san 10.27.10.60 --disable traefik --disable servicelb --disable local-storage
# cat /var/lib/rancher/k3s/server/node-token
# curl -sfL https://get.k3s.io | K3S_DATASTORE_ENDPOINT='mysql://k3s:k3spass@tcp(10.27.10.50:3306)/k3sdb' K3S_KUBECONFIG_MODE="644" sh -s - server --token=K101c176295e5e4170740c47488fe8ed9bc5ef7f1688582c06d42766e48f87cbf01::server:44d9d557a708f71a4d7ebcf91370a9a8 --tls-san 10.27.10.50 --disable traefik --disable servicelb --disable local-storage

# on the workers
# curl -sfL https://get.k3s.io | K3S_URL=https://10.27.10.50:6443 sh -s - agent --token=K101c176295e5e4170740c47488fe8ed9bc5ef7f1688582c06d42766e48f87cbf01::server:44d9d557a708f71a4d7ebcf91370a9a8

# get yaml file
# sudo cat /etc/rancher/k3s/k3s.yaml

# traefik
# metallb
# longhorn
# prometheus
# loki
# argo-cd
# keyclock
