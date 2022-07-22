Install Kubernetes Cluster using kubeadm
Follow this documentation to set up a Kubernetes cluster on CentOS 7.

This documentation guides you in setting up a cluster with one master node and one worker node.

Assumptions
Role	FQDN	IP	OS	RAM	CPU
Master	kmaster.example.com	172.16.16.100	CentOS 7	2G	2
Worker	kworker.example.com	172.16.16.101	CentOS 7	1G	1
On both Kmaster and Kworker
Perform all the commands as root user unless otherwise specified

Disable Firewall
systemctl disable firewalld; systemctl stop firewalld
Disable swap
swapoff -a; sed -i '/swap/d' /etc/fstab
Disable SELinux
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
Update sysctl settings for Kubernetes networking
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
Install docker engine
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce-19.03.12 
systemctl enable --now docker
Kubernetes Setup
Add yum repository
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
Install Kubernetes components
yum install -y kubeadm-1.18.5-0 kubelet-1.18.5-0 kubectl-1.18.5-0
Enable and Start kubelet service
systemctl enable --now kubelet
On kmaster
Initialize Kubernetes Cluster
kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16
Deploy Calico network
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
Cluster join command
kubeadm token create --print-join-command
To be able to run kubectl commands as non-root user
If you want to be able to run kubectl commands as non-root user, then as a non-root user perform these

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

On Kworker
Join the cluster
Use the output from kubeadm token create command in previous step from the master server and run here.

Verifying the cluster
Get Nodes status
kubectl get nodes
Get component status
kubectl get cs


-------------------------------------------------------------

install 

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

--------------------------------------------------------------

ubuntu

#!/bin/sh
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install  -y   apt-transport-https     ca-certificates     curl     software-properties-common
   
sudo apt-get install -y docker.io
   
   
sudo bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'
   
   
   
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   
sudo bash -c 'cat << EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF'
   
   
sudo apt update
   
sudo apt install -y kubelet kubeadm kubectl
   
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   
   
sleep 60
   
mkdir -p /home/ubuntu/.kube
   
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
   
chown ubuntu:ubuntu /home/ubuntu/.kube/config
 
sleep 60
 
export KUBECONFIG=/etc/kubernetes/admin.conf && kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
 
echo 'source <(kubectl completion bash)' >>  /home/ubuntu/.bashrc
 
# Allow workloads to be scheduled to the master node
kubectl taint nodes `hostname`  node-role.kubernetes.io/master:NoSchedule-
 
# Deploy the monitoring stack based on Heapster, Influxdb and Grafana
git clone https://github.com/kubernetes/heapster.git
cd heapster
 
# Change the default Grafana config to use NodePort so we can reach the Grafana UI over the Public/Floating IP
sed -i 's/# type: NodePort/type: NodePort/' deploy/kube-config/influxdb/grafana.yaml
 
kubectl create -f deploy/kube-config/influxdb/
kubectl create -f deploy/kube-config/rbac/heapster-rbac.yaml
 
 
# The commands below will deploy the Kubernetes dashboard
 
wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
echo '  type: NodePort' >> kubernetes-dashboard.yaml
kubectl create -f kubernetes-dashboard.yaml
 
# Create an admin user that will be needed in order to access the Kubernetes Dashboard
sudo bash -c 'cat << EOF > admin-user.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF'
 
kubectl create -f admin-user.yaml
 
# Create an admin role that will be needed in order to access the Kubernetes Dashboard
sudo bash -c 'cat << EOF > role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF'
 
kubectl create -f role-binding.yaml
 
 
# This command will create a token and print the command needed to join slave workers
kubeadm token create --print-join-command --ttl 24h
 
# This command will print the port exposed by the Grafana service. We need to connect to the floating IP:PORT later
kubectl get svc -n kube-system | grep grafana
 
# This command will print the port exposed by the Kubernetes dashboard service. We need to connect to the floating IP:PORT later
kubectl -n kube-system get service kubernetes-dashboard
 
 
# This command will print a token that can be used to authenticate in the Kubernetes dashboard
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | gr

	kubeadm join –token ca0872.c7e8654d399ff986 172.16.16.19:6443 –discovery-token-ca-cert-hash sha256:6861ba7543c750a44efe4165f82cc42046c186bd5f387f4f9984154c28531548

NOTE !!! The token is valid for 24h, so if you later want to add new Kubelet workers to the cluster, you will have to ssh into the Master node, become root by running “sudo su -“ and run:

root@kubernetes:~# kubeadm token create --print-join-command --ttl 24h
kubeadm join --token 123091.73f18d0e3afcd54b 172.16.16.15:6443 --discovery-token-ca-cert-
-----------------------------------------------------------