#!/bin/bash
echo "Installing containerd & runc & cni components"
mkdir -p k8s && cd k8s

echo "Adding master and nfs to /etc/hosts"
echo -e "\n# Kubernetes cluster\n10.100.1.103 nfs\n10.100.1.111 kmaster1\n" >> /etc/hosts

echo "Download containerd and extract to /usr/local"
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz && tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
containerd --version

echo "Download containerd service setting and copy to /lib/systemd/system/"
wget https://raw.githubusercontent.com/beeeeeeeeck/kubernetes-homelab-cluster/main/containerd.service -P /lib/systemd/system/
cat /lib/systemd/system/containerd.service

echo "System reload and enable containerd"
systemctl daemon-reload
systemctl enable --now containerd

echo "Configure containerd"
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
str1="registry.k8s.io/pause:3.8"
str2="registry.aliyuncs.com/google_containers/pause:3.9"
sed -i "/sandbox_image/ s%${str1}%${str2}%g" /etc/containerd/config.toml
sed -i '/SystemdCgroup/ s/false/true/g' /etc/containerd/config.toml
systemctl restart containerd && systemctl status containerd
cat /etc/containerd/config.toml
ps -e | grep containerd

echo "Download runc and install"
wget https://github.com/opencontainers/runc/releases/download/v1.1.7/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

echo "Download cni and extract to /opt/cni/bin/"
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
mkdir -p /opt/cni/bin
tar xf  cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/

echo "Prepare system setting for k8s"
modprobe overlay
modprobe br_netfilter
wget https://raw.githubusercontent.com/beeeeeeeeck/kubernetes-homelab-cluster/main/modules-load.d/k8s.conf -P /etc/modules-load.d/
cat /etc/modules-load.d/k8s.conf
wget https://raw.githubusercontent.com/beeeeeeeeck/kubernetes-homelab-cluster/main/sysctl.d/k8s.conf -P /etc/sysctl.d/
cat /etc/sysctl.d/k8s.conf
sysctl --system

echo "Clean up"
cd ..
rm -rf k8s
