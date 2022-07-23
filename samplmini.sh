Step 1: Update system
Run the following commands to update all system packages to the latest release:

sudo yum -y update
Step 2: Install KVM Hypervisor
As stated earlier, we’ll use KVM as Hypervisor of choice for the Minikube VM. Here is our complete guide on the installation of KVM on CentOS / RHEL 8.
How To Install KVM on RHEL 8 / CentOS 8 Linux
Install KVM on CentOS 7
Confirm that libvirtd service is running.

$ systemctl status libvirtd
● libvirtd.service - Virtualization daemon
   Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2020-01-20 14:33:07 EAT; 1s ago
     Docs: man:libvirtd(8)
           https://libvirt.org
 Main PID: 20569 (libvirtd)
    Tasks: 20 (limit: 32768)
   Memory: 70.4M
   CGroup: /system.slice/libvirtd.service
           ├─ 2653 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
           ├─ 2654 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
           └─20569 /usr/sbin/libvirtd

Jan 20 14:33:07 cent8.localdomain systemd[1]: Starting Virtualization daemon...
Jan 20 14:33:07 cent8.localdomain systemd[1]: Started Virtualization daemon.
Jan 20 14:33:08 cent8.localdomain dnsmasq[2653]: read /etc/hosts - 2 addresses
Jan 20 14:33:08 cent8.localdomain dnsmasq[2653]: read /var/lib/libvirt/dnsmasq/default.addnhosts - 0 addresses
Jan 20 14:33:08 cent8.localdomain dnsmasq-dhcp[2653]: read /var/lib/libvirt/dnsmasq/default.hostsfile
If not running after installation, then start and set it to start at boot.

sudo systemctl enable --now libvirtd
You user should be part of libvirt group.
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt
Open the file /etc/libvirt/libvirtd.conf for editing.

sudo vi /etc/libvirt/libvirtd.conf
Set the UNIX domain socket group ownership to libvirt, (around line 85)

unix_sock_group = "libvirt"
Set the UNIX socket permissions for the R/W socket (around line 102)

unix_sock_rw_perms = "0770"
Restart libvirt daemon after making the change.
sudo systemctl restart libvirtd.service
Step 3: Download minikube
You need to download the minikube binary. I will put the binary under /usr/local/bin directory since it is inside $PATH.

sudo yum -y install wget
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
Confirm installation of Minikube on your system.

$ minikube version
minikube version: v1.23.2
commit: 0a0ad764652082477c00d51d2475284b5d39ceed
Step 4: Install kubectl
We need kubectl which is a command-line tool used to deploy and manage applications on Kubernetes.

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
Give the file executable bit and move to a location in your PATH.

chmod +x kubectl
sudo mv kubectl  /usr/local/bin/
Confirm the version of kubectl installed.

$ kubectl version --client -o json
{
  "clientVersion": {
    "major": "1",
    "minor": "22",
    "gitVersion": "v1.22.2",
    "gitCommit": "8b5a19147530eaac9476b0ab82980b4088bbc1b2",
    "gitTreeState": "clean",
    "buildDate": "2021-09-15T21:38:50Z",
    "goVersion": "go1.16.8",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}
Step 5: Starting minikube
Now that components are installed, you can start minikube. VM image will be downloaded and configured for Kubernetes single node cluster.

Edit Libvirtd configuration file and set group:

$ sudo vim /etc/libvirt/libvirtd.conf
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
Restart libvirtd daemon:

sudo systemctl restart libvirtd
Add your username to libvirt group:

$ sudo usermod -aG libvirt $USER
$ newgrp libvirt
$ id
uid=1000(jkmutai) gid=989(libvirt) groups=989(libvirt),10(wheel),1000(jkmutai)
For a list of options, run:

$ minikube start --help
To create a minikube VM with the default options, run:

$ minikube start
The default container runtime to be used is docker, but you can also use crio or containerd:

$ minikube start --container-runtime=cri-o
$ minikube start --container-runtime=containerd
The installer will automatically detect KVM and download KVM driver.

* minikube v1.23.2 on CentOS 8.4
* Automatically selected the kvm2 driver
* Downloading driver docker-machine-driver-kvm2:
    > docker-machine-driver-kvm2....: 65 B / 65 B [----------] 100.00% ? p/s 0s
    > docker-machine-driver-kvm2: 11.40 MiB / 11.40 MiB  100.00% 1.09 MiB p/s 1
* Downloading VM boot image ...
    > minikube-v1.23.1.iso.sha256: 65 B / 65 B [-------------] 100.00% ? p/s 0s
    > minikube-v1.23.1.iso: 225.22 MiB / 225.22 MiB  100.00% 103.78 MiB p/s 2.4
* Starting control plane node minikube in cluster minikube
....
If you have more than one hypervisor, then specify it.

$ minikube start --vm-driver kvm2
Please note that latest stable release of Kubernetes is installed. Use --kubernetes-version flag to specify version to be installed. Example:

--kubernetes-version='v1.22.2'
Wait for the download and setup to finish then confirm that everything is working fine.

$ minikube start
* minikube v1.23.2 on Centos 8.4
* Automatically selected the kvm2 driver
* Downloading driver docker-machine-driver-kvm2:
    > docker-machine-driver-kvm2....: 65 B / 65 B [----------] 100.00% ? p/s 0s
    > docker-machine-driver-kvm2: 11.40 MiB / 11.40 MiB  100.00% 1.09 MiB p/s 1
* Downloading VM boot image ...
    > minikube-v1.23.1.iso.sha256: 65 B / 65 B [-------------] 100.00% ? p/s 0s
    > minikube-v1.23.1.iso: 225.22 MiB / 225.22 MiB  100.00% 103.78 MiB p/s 2.4
* Starting control plane node minikube in cluster minikube
* Downloading Kubernetes v1.22.2 preload ...
    > preloaded-images-k8s-v13-v1...: 579.88 MiB / 579.88 MiB  100.00% 71.91 Mi
* Creating kvm2 VM (CPUs=2, Memory=6000MB, Disk=20000MB) ...
* Deleting "minikube" in kvm2 ...
* Creating kvm2 VM (CPUs=2, Memory=6000MB, Disk=20000MB) ...
* Preparing Kubernetes v1.22.2 on CRI-O 1.22.0 ...
  - Generating certificates and keys ...
  - Booting up control plane ...
  - Configuring RBAC rules ...
* Configuring bridge CNI (Container Networking Interface) ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
Step 6: Minikube Basic operations
The kubectl command line tool is configured to use “minikube“.

To check cluster status, run:

$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

$ kubectl cluster-info
Kubernetes master is running at https://192.168.39.2:8443
KubeDNS is running at https://192.168.39.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
Your Minikube configuration file is located under ~/.minikube/machines/minikube/config.json

To View Config, use:

$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/jkmutai/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Mon, 27 Sep 2021 00:44:49 EAT
        provider: minikube.sigs.k8s.io
        version: v1.23.2
      name: cluster_info
    server: https://192.168.39.195:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Mon, 27 Sep 2021 00:44:49 EAT
        provider: minikube.sigs.k8s.io
        version: v1.23.2
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/jkmutai/.minikube/profiles/minikube/client.crt
    client-key: /home/jkmutai/.minikube/profiles/minikube/client.key
To check running nodes:

$ kubectl get nodes
NAME       STATUS   ROLES                  AGE     VERSION
minikube   Ready    control-plane,master   2m53s   v1.22.2
Access minikube VM using ssh:

$ minikube ssh

                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ sudo su -
# cat /etc/os-release
NAME=Buildroot
VERSION=2021.02.4-dirty
ID=buildroot
VERSION_ID=2021.02.4
PRETTY_NAME="Buildroot 2021.02.4"
# exit
logout
$ exit
logout
To stop a running local kubernetes cluster, run:

$ minikube stop
* Stopping "minikube" in kvm2 ...
* "minikube" stopped.
To start VM, run:

$ minikube start
* minikube v1.23.2 on CentOS 8.4
* Using the kvm2 driver based on existing profile
* Starting control plane node minikube in cluster minikube
* Restarting existing kvm2 VM for "minikube" ...
* Preparing Kubernetes v1.22.2 on CRI-O 1.22.0 ...
* Configuring bridge CNI (Container Networking Interface) ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
To delete a local kubernetes cluster, use:

$ minikube delete
Step 7: Enable Kubernetes Dashboard
Kubernetes ships with a web dashboard which allows you to manage your cluster without interacting with a command line. The dashboard addon is installed and enabled by default on minikube.

$ minikube addons list
|-----------------------------|----------|--------------|-----------------------|
|         ADDON NAME          | PROFILE  |    STATUS    |      MAINTAINER       |
|-----------------------------|----------|--------------|-----------------------|
| ambassador                  | minikube | disabled     | unknown (third-party) |
| auto-pause                  | minikube | disabled     | google                |
| csi-hostpath-driver         | minikube | disabled     | kubernetes            |
| dashboard                   | minikube | disabled     | kubernetes            |
| default-storageclass        | minikube | enabled ✅   | kubernetes            |
| efk                         | minikube | disabled     | unknown (third-party) |
| freshpod                    | minikube | disabled     | google                |
| gcp-auth                    | minikube | disabled     | google                |
| gvisor                      | minikube | disabled     | google                |
| helm-tiller                 | minikube | disabled     | unknown (third-party) |
| ingress                     | minikube | disabled     | unknown (third-party) |
| ingress-dns                 | minikube | disabled     | unknown (third-party) |
| istio                       | minikube | disabled     | unknown (third-party) |
| istio-provisioner           | minikube | disabled     | unknown (third-party) |
| kubevirt                    | minikube | disabled     | unknown (third-party) |
| logviewer                   | minikube | disabled     | google                |
| metallb                     | minikube | disabled     | unknown (third-party) |
| metrics-server              | minikube | disabled     | kubernetes            |
| nvidia-driver-installer     | minikube | disabled     | google                |
| nvidia-gpu-device-plugin    | minikube | disabled     | unknown (third-party) |
| olm                         | minikube | disabled     | unknown (third-party) |
| pod-security-policy         | minikube | disabled     | unknown (third-party) |
| portainer                   | minikube | disabled     | portainer.io          |
| registry                    | minikube | disabled     | google                |
| registry-aliases            | minikube | disabled     | unknown (third-party) |
| registry-creds              | minikube | disabled     | unknown (third-party) |
| storage-provisioner         | minikube | enabled ✅   | kubernetes            |
| storage-provisioner-gluster | minikube | disabled     | unknown (third-party) |
| volumesnapshots             | minikube | disabled     | kubernetes            |
|-----------------------------|----------|--------------|-----------------------|
Enabling plugins:

minikube addons enable <plugin-name>
Example:

$ minikube addons enable csi-hostpath-driver
! [WARNING] For full functionality, the 'csi-hostpath-driver' addon requires the 'volumesnapshots' addon to be enabled.

You can enable 'volumesnapshots' addon by running: 'minikube addons enable volumesnapshots'

  - Using image k8s.gcr.io/sig-storage/livenessprobe:v2.2.0
  - Using image k8s.gcr.io/sig-storage/csi-provisioner:v2.1.0
  - Using image k8s.gcr.io/sig-storage/csi-attacher:v3.1.0
  - Using image k8s.gcr.io/sig-storage/csi-external-health-monitor-controller:v0.2.0
  - Using image k8s.gcr.io/sig-storage/hostpathplugin:v1.6.0
  - Using image k8s.gcr.io/sig-storage/csi-snapshotter:v4.0.0
  - Using image k8s.gcr.io/sig-storage/csi-external-health-monitor-agent:v0.2.0
  - Using image k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.0.1
  - Using image k8s.gcr.io/sig-storage/csi-resizer:v1.1.0
* Verifying csi-hostpath-driver addon...
* The 'csi-hostpath-driver' addon is enabled
To open directly on your default browser, use:

$ minikube dashboard
* Enabling dashboard ...
  - Using image kubernetesui/metrics-scraper:v1.0.7
  - Using image kubernetesui/dashboard:v2.3.1
* Verifying dashboard health ...
* Launching proxy ...
* Verifying proxy health ...
* Opening http://127.0.0.1:39649/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...
  http://127.0.0.1:39649/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
To get the URL of the dashboard

$ minikube dashboard --url
http://192.168.39.117:30000
