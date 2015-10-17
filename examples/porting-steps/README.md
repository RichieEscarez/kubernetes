<!-- BEGIN MUNGE: UNVERSIONED_WARNING -->

<!-- BEGIN STRIP_FOR_RELEASE -->

<img src="http://kubernetes.io/img/warning.png" alt="WARNING"
     width="25" height="25">
<img src="http://kubernetes.io/img/warning.png" alt="WARNING"
     width="25" height="25">
<img src="http://kubernetes.io/img/warning.png" alt="WARNING"
     width="25" height="25">
<img src="http://kubernetes.io/img/warning.png" alt="WARNING"
     width="25" height="25">
<img src="http://kubernetes.io/img/warning.png" alt="WARNING"
     width="25" height="25">

<h2>PLEASE NOTE: This document applies to the HEAD of the source tree</h2>

If you are using a released version of Kubernetes, you should
refer to the docs that go with that version.

<strong>
The latest 1.0.x release of this document can be found
[here](http://releases.k8s.io/release-1.0/examples/porting-steps/README.md).

Documentation for other releases can be found at
[releases.k8s.io](http://releases.k8s.io).
</strong>
--

<!-- END STRIP_FOR_RELEASE -->

<!-- END MUNGE: UNVERSIONED_WARNING -->

# Tutorial: Porting apps into containers and running them in Kubernetes clusters

Use this tutorial to help you understand the task of porting a simple two-tier application into a [Kubernetes cluster](../../docs/user-guide/overview.md).

  - [Overview](#overview)
  - [Before you begin](#before-you-begin)
  - [Prerequisites](#prerequisites)
  - [1. Installing and running the app locally](#1-installing-and-running-the-app-locally)
  - [2. Running the app in containers](#2-running-the-app-in-containers)
  - [3. Running the containerized app in a Kubernetes cluster](#3-running-the-containerized-app-in-a-kubernetes-cluster)
  - [4. Extended learning: Using secrets for your passwords](#4-extended-learning-using-secrets-for-your-passwords)

----------

## Overview

This tutorial covers the common steps for porting a locally running two-tier app into containers and then running those containers in an existing Kubernetes cluster.

The two-tier app that is used to demonstrate the process is a simple guestbook (front-end) that connects to a MySQL database (back-end). The guestbook (app.go) is written in the Go language to connect to a MySQL server, create a database if one does not exist, and then store user input from a web interface into that database.

In general, when you port your two-tier app into containers and then into Kubernetes, you must modify your app to ensure that it runs in each environment. For example, at each step in this tutorial the example guestbook app is modified to ensure that the front-end and back-end continue to connect to each other.

The steps used to demonstrate the process of porting over a simple two-tier app include:

 1. **Run the app locally** *(optional)*: Install and run the app on your local computer.
 1. **Containerize the app**: Port the app into containers and then run them with the Docker Engine.
 1. **Run the containers in a cluster**: Port the containerized version of the app into Kubernetes and then run it in your cluster.

Each step is explained below in detail.

----------

## Before you begin

It's your choice. You can follow along step-by-step by using the provided example guestbook app or instead review the process to learn how to port over your own app.

Instructions and a version of the example guestbook app are provided for each environment so that you can experience the entire process. Optionally, since each version of the example guestbook app is pre-configured to stand alone, you can join in and follow along at any point.

> **Extended learning:** This tutorial also covers some optional advanced steps about how to create and use secrets for your passwords in Kubernetes. Details are provided in [Step #4](#4-extended-learning-using-secrets-to-store-your-passwords).

----------

## Prerequisites

To follow along with the steps in this tutorial, you must meet the prerequisites listed below.

This tutorial assumes that you are familiar with the following objects and their architecture:

 * Docker containers. To learn more about containers, see the [Quickstart containers](http://docs.docker.com/engine/userguide/basics/) topic.
 * Kubernetes clusters and their replication controllers, pods, and services. To learn more about clusters, see the [Managing Applications](../../docs/user-guide/README.md) guide. <br/>*Tip*: If you used one of the Kubernetes getting started guides to create your cluster, you should be prepared enough to complete this tutorial.

The following prerequisites differ by environment and depend on when you decide to follow along. For specific details, see the individual tutorial steps.

 * Software prerequisites for porting your apps:
    * Download and install the Docker Engine. For details, see [Install Docker Engine](https://docs.docker.com/installation/).
    * Install Kubernetes and then create and run a cluster. For details, see [Creating a Kubernetes Cluster](../../docs/getting-started-guides/README.md).
    * Create an account in a registry where you can push your container images. For example, an account in either [Docker Hub](https://hub.docker.com/), [Google Container Registry](https://cloud.google.com/tools/container-registry/), or another private container registry. For details, see the Kubernetes [Images](../../docs/user-guide/images.md) topic.

 * Other prerequisites for following along step-by-step:
    * Install and configure the Go build environment. For details, see the [Getting Started](http://golang.org/doc/install) topic.
    * Download and install the MySQL server. For details, see the [MySQL downloads](http://dev.mysql.com/downloads/) page.
    * Create a Google Compute Engine project on Google Cloud Platform. For a trial, see [Google Cloud Platform Pricing](https://cloud.google.com/pricing/).
    * Install and configure the Google Cloud SDK. For details, see [Installation and Quick Start](https://cloud.google.com/sdk/#Quick_Start).

----------

## 1. Installing and running the app locally

This is an optional first step in the tutorial that is provided to help you walk through and understand the process of porting an app into Kubernetes in it's entirety. In this step you install and configure the example guestbook app on your local computer. The example guestbook app is then used through the remainder of the tutorial to demonstrate each step in the process.

> **Tip**: If you already have an app that you want to run in a Kubernetes cluster, you can skip to the next step to learn about porting that app into a container.

#### - [Install and run the app locally](local/README.md)

----------

## 2. Running the app in containers

In this step, the app that you have running on your local computer is modified to run in containers. This step includes creating a `Dockerfile` for each container and then building and running those containers with a local installation of the Docker Engine.

#### - [Run the app in containers](containers/README.md)

----------

## 3. Running the containerized app in a Kubernetes cluster

In this step, the containerized version of your app is modified and configured to run in Kubernetes. This step includes building and pushing your containers to a registry, creating configuration files to define each container to the cluster, and then deploying your containers to run the app in your cluster.

#### - [Run the containerized app in a Kubernetes cluster](k8s/README.md)

----------

## 4. Extended learning: Using secrets for your passwords

In this optional step, the version of your app that you have running in Kubernetes is modified to use Kubernetes secrets for storing your sensitive data such as passwords. This step includes creating the Kubernetes secret object and then updating the pods in your cluster for which you want using that secret.

#### - [Use secrets to store your passwords](secret/README.md)

----------

***Next steps***: Learn how to administer your applications and clusters in Kubernetes:

 * [Kubernetes User Guide: Managing Applications](../../docs/user-guide/README.md)
 * [Kubernetes Cluster Admin Guide](../../docs/admin/introduction.md)

<!-- BEGIN MUNGE: GENERATED_ANALYTICS -->
[![Analytics](https://kubernetes-site.appspot.com/UA-36037335-10/GitHub/examples/porting-steps/README.md?pixel)]()
<!-- END MUNGE: GENERATED_ANALYTICS -->
