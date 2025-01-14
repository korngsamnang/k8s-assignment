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
