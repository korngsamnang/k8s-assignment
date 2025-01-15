# Kubernetes Cluster on EC2 with Web App and MongoDB

## Table of Contents

1. [Goal](#goal)
2. [Prerequisites](#prerequisites)
3. [Project Overview](#project-overview)
4. [Set up EC2 Instances with Terraform](#set-up-ec2-instances-with-terraform)
5. [Creating a Cluster on EC2 (from Scratch)](#creating-a-cluster-on-ec2-from-scratch)
6. [Deploy all Kubernetes Resources](#deploy-all-kubernetes-resources)
7. [Access the Application](#access-the-application)
8. [Troubleshooting](#troubleshooting)
9. [Conclusion](#conclusion)
10. [References](#references)

## Goal

The goal of this project is to set up a Kubernetes cluster on EC2 instances, deploy a web application, and connect it to a MongoDB database. This includes:

1. Deploying MongoDB with secure configuration.
2. Deploying a web application that connects to MongoDB.
3. Exposing the web app for external access.

## Prerequisites

-   AWS account with permissions to create EC2 instances.
-   Terraform installed locally.
-   Basic understanding of Kubernetes concepts (pods, services, configmaps, secrets, etc).

    > Kubernetes Architecture
    > ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406651320-3de14bfa-d09d-4b56-b509-e4ceccb9caac.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T091710Z&X-Amz-Expires=300&X-Amz-Signature=af9190f6d0a21cc4d63ed70e0bb5b323d27c55b517d7f1bd3423c179becadeb5&X-Amz-SignedHeaders=host)

## Project Overview

We will deploy a mongodb database and a web application which will connect to the mongodb using external configuration data from cofigmap and secret.
And finally we will make our application accessible externally from the browser.

> Project Overview
> ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406658204-d6bece49-c501-4718-95a5-671e4d45790a.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T113308Z&X-Amz-Expires=300&X-Amz-Signature=18c75e6832e035f43ce4159159883982dc4ada3278642484e45ba4990af49722&X-Amz-SignedHeaders=host)

## Set up EC2 Instances with Terraform

### Step 1: Install Prerequisites

Ensure you have the following installed:

-   **Terraform**: [Download Terraform](https://www.terraform.io/downloads.html)
-   **AWS CLI**: [Download AWS CLI](https://aws.amazon.com/cli/)
-   **AWS Credentials**: Run `aws configure` to set up your AWS access key and secret access key.

### Step 2: Initialize Terraform

Navigate to the `terraform` directory and initialize the configuration:

```bash
terraform init
```

### Step 3: Review the Terraform Plan

Preview the resources that will be created:

```bash
terraform plan
```

### Step 4: Apply the Terraform Configuration

Apply the configuration to create EC2 instances (1 control plane and 2 worker nodes):

```bash
terraform apply
```

Confirm with `yes` when prompted.

## Creating a Cluster on EC2 (from Scratch)

### Initial Setup on All Servers (Control Plane, Worker 1, Worker 2)

1. **Update and Upgrade the System:**

    ```bash
    sudo apt update
    sudo apt upgrade
    ```

2. **Set Hostnames:**

-   Control Plane:

    ```bash
    sudo hostnamectl set-hostname k8s-control
    ```

-   Worker 1:

    ```bash
    sudo hostnamectl set-hostname k8s-worker1
    ```

-   Worker 2:

    ```bash
    sudo hostnamectl set-hostname k8s-worker2
    ```

3. **Update `/etc/hosts` File:**

-   Get the internal IP addresses of all three instances from the AWS console.

-   Add the following entries to the /etc/hosts file on all servers:

    ```bash
    [Control Plane Internal IP] kubernetes-control
    [Worker 1 Internal IP] kubernetes-worker1
    [Worker 2 Internal IP] kubernetes-worker2
    ```

4.  **Enable Overlay and `br_netfilter` Modules:**

    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
    overlay
    br_netfilter
    EOF
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```

5.  **Enable Networking Configurations::**

    ```bash
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
    net.bridge.bridge-nf-call-iptables=1
    net.ipv4.ip_forward=1
    net.bridge.bridge-nf-call-ip6tables=1
    EOF
    ```

**Containerd Installation on All Servers**

1.  Install Required Packages:

    ```bash
    sudo apt update
    sudo apt install curl ca-certificates gnupg
    ```

2.  Install Containerd:

    ```bash
    sudo apt update
    sudo apt install -y containerd.io
    ```

3.  Configure Containerd:

    ```bash
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    ```

4.  Disable Swap:

    ```bash
    sudo swapoff -a
    ```

5.  Restart Containerd:
    ```bash
    sudo systemctl restart containerd
    ```

**Kubernetes Installation on All Servers**

1. Add Kubernetes APT Repository:

    ```bash
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
    deb https://apt.kubernetes.io/ kubernetes-xenial main
    EOF
    sudo apt update
    ```

2. Install Kubernetes Components:

    ```bash
    sudo apt install -y kubelet=1.28.0-00 kubeadm=1.28.0-00 kubectl=1.28.0-00
    ```

3. Mark Kubernetes Packages on Hold:
    ```bash
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

**Control Plane Initialization (Only on Control Plane Server)**

1. Initialize the Control Plane:

    ```bash
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version=1.28.0
    ```

2. Set up Kubernetes Configuration:

    ```bash
     mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

3. Install Calico Networking:

    ```bash
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    ```

4. Generate the Join Command:
    ```bash
    kubeadm token create --print-join-command
    ```

**Worker Node Joining (On Worker 1 and Worker 2)**

1. Restart Containerd:

    ```bash
    sudo systemctl restart containerd
    ```

2. Join Worker Nodes to the Cluster:

-   Run the kubeadm join command generated on the control plane, which includes a token and the control plane’s IP address.

    ```bash
    kubeadm join <Control Plane IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

    ```

> k8s cluster
> ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406659927-a68aef12-6415-4e03-9302-c2c4c85e2226.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T120848Z&X-Amz-Expires=300&X-Amz-Signature=8731839685e555e174fd18df25aec910615885b9f14f2552aa02876c2a917d65&X-Amz-SignedHeaders=host)
