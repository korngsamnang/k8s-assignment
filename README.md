# Kubernetes Cluster on EC2 with Web App and MongoDB

## Table of Contents

1. [Goal](#goal)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Step-by-Step Guide](#step-by-step-guide)
    - [4.1 Provisioning EC2 Instances with Terraform](#41-provisioning-ec2-instances-with-terraform)
    - [4.2 Creating a Cluster on EC2 (from Scratch)](#42-creating-a-cluster-on-ec2-from-scratch)
    - [4.3 Deploying the Web App](#43-deploying-the-web-app)
    - [4.4 Setting Up MongoDB](#44-setting-up-mongodb)
5. [Access the Application](#access-the-application)
6. [Future Improvements](#future-improvements)

## Goal

The goal of this project is to set up a Kubernetes cluster on EC2 instances, deploy a web application, and connect it to a MongoDB database. This includes:

1. Deploying MongoDB with secure configuration.
2. Deploying a web application that connects to MongoDB.
3. Exposing the web app for external access.

## Prerequisites

-   AWS account with permissions to create EC2 instances.
-   Terraform installed locally.
-   Basic understanding of Kubernetes concepts (pods, services, configmaps, secrets, etc).
