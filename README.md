# Kubernetes Cluster on EC2 with Web App and MongoDB

## Table of Contents

1. [Goal](#goal)
2. [Prerequisites](#prerequisites)
3. [Project Overview](#project-overview)
4. [Set up EC2 Instances with Terraform](#set-up-ec2-instances-with-terraform)
5. [Creating a Cluster on EC2 (from Scratch)](#creating-a-cluster-on-ec2-from-scratch)
6. [Deploy WebApp with MongoDB](#deploy-webapp-with-mongodb)

## 1. Goal

The goal of this project is to set up a Kubernetes cluster on EC2 instances, deploy a web application, and connect it to a MongoDB database. This includes:

1. Deploying MongoDB with secure configuration.
2. Deploying a web application that connects to MongoDB.
3. Exposing the web app for external access.

## 2. Prerequisites

-   AWS account with permissions to create EC2 instances.
-   Terraform installed locally.
-   Basic understanding of Kubernetes concepts (pods, services, configmaps, secrets, etc).

    > Kubernetes Architecture
    > ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406651320-3de14bfa-d09d-4b56-b509-e4ceccb9caac.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T091710Z&X-Amz-Expires=300&X-Amz-Signature=af9190f6d0a21cc4d63ed70e0bb5b323d27c55b517d7f1bd3423c179becadeb5&X-Amz-SignedHeaders=host)

## 3. Project Overview

We will deploy a mongodb database and a web application which will connect to the mongodb using external configuration data from cofigmap and secret.
And finally we will make our application accessible externally from the browser.

> Project Overview
> ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406658204-d6bece49-c501-4718-95a5-671e4d45790a.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T113308Z&X-Amz-Expires=300&X-Amz-Signature=18c75e6832e035f43ce4159159883982dc4ada3278642484e45ba4990af49722&X-Amz-SignedHeaders=host)

## 4. Set up EC2 Instances with Terraform

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

## 5. Creating a Cluster on EC2 (from Scratch)

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
> ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406683377-7a9842cc-2381-4ff0-83c1-5f90109accc3.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T192656Z&X-Amz-Expires=300&X-Amz-Signature=0e0189a1ace383b699bce40593a61b8832991b2964aefb229ea1457b4215112b&X-Amz-SignedHeaders=host)

## 6. Deploy WebApp with MongoDB

### Prerequisites

Before deploying the web app and MongoDB, make sure you have:

-   A running Kubernetes cluster (with a control plane and worker nodes).
-   The required configuration files in the `app/` directory:
    -   `mongo-config.yaml`
    -   `mongo-secret.yaml`
    -   `mongo.yaml`
    -   `webapp.yaml`

### Step 1: Apply MongoDB Configuration

1. **MongoDB ConfigMap**:

    - `mongo-config.yaml` contains the MongoDB configuration settings. Apply the ConfigMap:
        ```bash
        kubectl apply -f app/mongo-config.yaml
        ```

2. **MongoDB Secret**:

    - `mongo-secret.yaml` contains sensitive data (e.g., passwords) for MongoDB. Apply the Secret:
        ```bash
        kubectl apply -f app/mongo-secret.yaml
        ```

3. **MongoDB Deployment**:
    - `mongo.yaml` defines the MongoDB deployment (including the StatefulSet or Deployment for MongoDB). Apply the MongoDB deployment:
        ```bash
        kubectl apply -f app/mongo.yaml
        ```

### Step 2: Apply Web App Configuration

1. **Web App Deployment**:
    - `webapp.yaml` defines the deployment of your web app, including the service that exposes it. Apply the web app configuration:
        ```bash
        kubectl apply -f app/webapp.yaml
        ```

### Step 3: Verify Deployment

To ensure that everything is deployed correctly, check the status of the pods and services:

-   **Check Pods**:
    ```bash
    kubectl get pods
    kubectl get svc
    ```
    > Verify Deployment
    > ![image](https://github-production-user-asset-6210df.s3.amazonaws.com/99709883/406683632-1d1aa73e-3750-4a9e-bf92-76da67e32ef9.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20250125%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250125T193051Z&X-Amz-Expires=300&X-Amz-Signature=2dd51ceefaff0bbc72b5ee496ee475014fa622126e84c6e4bd226f9c85f7c9dc&X-Amz-SignedHeaders=host)
