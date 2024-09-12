# installing Long horn
## install dependencies

### installing iscsi
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/prerequisite/longhorn-iscsi-installation.yaml --wait
```

check installation status
```
kubectl get pod | grep longhorn-iscsi-installation
```

check ststus sghould mentioned someting like this
```
kubectl logs longhorn-iscsi-installation-xxxxx -c iscsi-installation
```

The result
```
IProcessing triggers for libc-bin (2.35-0ubuntu3.6) ...
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for initramfs-tools (0.140ubuntu13.1) ...
update-initramfs: Generating /boot/initrd.img-6.5.0-18-generic
iscsi install successfully
```

if ok, remove the pods
```
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/prerequisite/longhorn-iscsi-installation.yaml
```

### Installing NFSv4 client

To enable Longhorn’s backup functionality and ensure proper operation, the NFSv4 client must be installed on the worker nodes within your cluster.

Follow these steps to set up the necessary components:

```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/prerequisite/longhorn-nfs-installation.yaml
```

After deploying the NFSv4 client, confirm the status of the installer pods using the following command:

```
kubectl get pod | grep longhorn-nfs-installation
```

The results
```
NAME                                  READY   STATUS    RESTARTS   AGE
longhorn-nfs-installation-mt5p7   1/1     Running   0          143m
longhorn-nfs-installation-n6nnq   1/1     Running   0          143m
And also can check the log with the following command to see the installation result:
```
```
kubectl logs longhorn-nfs-installation-mt5p7 -c nfs-installation
```
The results
```
rpc-svcgssd.service is a disabled or a static unit, not starting it.
rpc_pipefs.target is a disabled or a static unit, not starting it.
var-lib-nfs-rpc_pipefs.mount is a disabled or a static unit, not starting it.
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for libc-bin (2.35-0ubuntu3.6) ...
nfs install successfully
Once the NFSv4 installed successfully, Then you can safely uninstall the above with following command.
```
```
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.0/deploy/prerequisite/longhorn-nfs-installation.yaml
```
## 2. Installing Longhorn
added longhorn chart
```
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

Installing
```
helm install longhorn longhorn/longhorn -f value.yaml --namespace longhorn-system --create-namespace
```

## Uninstalling LongHorn

If any reason we would like to uninstall Longhorn helm then the below commands will help.
```
# Update `deleting-confirmation-flag` to allows uninstall longhorn
kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
# Uninstall longhorn
helm uninstall longhorn -n longhorn-system
# Delete namespace
kubectl delete namespace longhorn-system
```

// https://medium.com/@stevenhoang/step-by-step-guide-hosting-longhorn-on-k3s-arm-2328283d7244