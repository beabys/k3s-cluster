# Consul
## Add the HashiCorp Helm Repository:
```bash
$ helm repo add hashicorp https://helm.releases.hashicorp.com
 "hashicorp" has been added to your repositories
```

Verify that you have access to the consul chart:
```bash
$ helm search repo hashicorp/consul
NAME                CHART VERSION   APP VERSION DESCRIPTION
hashicorp/consul    1.0.1           1.14.1      Official HashiCorp Consul Chart
```

Before you install Consul on Kubernetes with Helm, ensure that the consul Kubernetes namespace does not exist. We recommend installing Consul on a dedicated namespace.

```bash
$ kubectl get namespace
NAME              STATUS   AGE
default           Active   18h
kube-node-lease   Active   18h
kube-public       Active   18h
kube-system       Active   18h
```

Install Consul on Kubernetes using Helm. The Helm chart does everything to set up your deployment: after installation, agents automatically form clusters, elect leaders, and run the necessary agents.

Run the following command to install the latest version of Consul on Kubernetes with its default configuration.
```bash
$ helm install consul hashicorp/consul --set global.name=consul --create-namespace --namespace consul
```

You can also install Consul on a dedicated namespace of your choosing by modifying the value of the -n flag for the Helm install.

To install a specific version of Consul on Kubernetes, issue the following command with --version flag:
```bash
$ export VERSION=1.0.1
$ helm install consul hashicorp/consul --set global.name=consul --version ${VERSION} --create-namespace --namespace consul
```

## Custom installation
If you want to customize your installation, create a values.yaml file to override the default settings. To learn what settings are available, run 
```bash
helm inspect values hashicorp/consul 
```

or read the Helm Chart Reference.

Minimal values.yaml for Consul service mesh
The following values.yaml config file contains the minimum required settings to enable Consul Service Mesh:

values.yaml
```yaml
global:
  name: consul
```

After you create your values.yaml file, run helm install with the --values flag:

```bash
$ helm install consul hashicorp/consul --create-namespace --namespace consul --values values.yaml
NAME: consul
...
```