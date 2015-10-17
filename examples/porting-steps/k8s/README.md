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
[here](http://releases.k8s.io/release-1.0/examples/porting-steps/k8s/README.md).

Documentation for other releases can be found at
[releases.k8s.io](http://releases.k8s.io).
</strong>
--

<!-- END STRIP_FOR_RELEASE -->

<!-- END MUNGE: UNVERSIONED_WARNING -->

# Running the containerized app in a Kubernetes cluster

You must modify and configure the containerized version of your two-tier app before you can deploy and run the app in a Kubernetes cluster.

Because Kubernetes is declarative, you must create Kubernetes configuration files to define each of your container images. You can think of these Kubernetes configuration files as replacements for the several Docker commands that are necessary for running and managing containers with the Docker Engine. In addition, you must also push your container images to a registry before you can run them in Kubernetes.

In this step, the version of the two-tier guestbook app that you have running with the Docker engine is used to demonstrate how to modify your app so that you can run it in your cluster. To run the guestbook app in Kubernetes, you must perform the following steps:

 * Modify the app to use the environment variables that are created with Kubernetes services.
 * Build a new container image for the front-end and then push it to a registry.
 * Create Kubernetes configuration files, one for each container image.
 * Define and use persistent disk storage.
 * Deploy the app to a cluster that's hosted in Google Cloud Platform.

In general, you create Kubernetes configuration files to define all the details that are necessary to run your app in your cluster. When you deploy your app to your cluster, the configuration files create corresponding Kubernetes components, including:

 * Replication controllers
 * Type and number of pods to replicate
 * Services

### Key learning points

In this step, you learn:

 * How you can easily port a container from running on your local Docker engine, to running in Kubernetes regardless of where your cluster is hosted, including
    * Pushing your container images to a registry. For details, see [Images](../../docs/user-guide/images.md).
    * Creating Kubernetes configuration files. For details, see [Configuration in Kubernetes](../../docs/user-guide/configuring-containers.md#configuration-in-kubernetes).
    * Creating Kubernetes replication controllers, pods, and services. For details, see [Replication Controller](../../docs/user-guide/replicationcontroller.md), [Pods](services), and [Services](../../docs/user-guide/pods.md).
 * How Kubernetes simplifies the tasks involved with running containers, including:
    * Pulling your container images from registries. For details, see [](../../.md).
    * Deploying and running multiple pod replicas. For details, see [](../../.md).
    * Configuring networking and discovery. For details, see [](../../.md).
 * How to configure the following Google Cloud Platform features:
    * Persistent storage
    * External IPs

    See the [Google Cloud Platform](https://cloud.google.com/) site for more information.

------------

## Before you begin

Similar to porting your app into a container, depending on the complexity and dependencies of your app, there might be additional steps for configuring and running your containerized app in Kubernetes that are not covered in this tutorial.

For example, the Kubernetes cluster that is used in this tutorial is running in Google Compute Engine. Depending on where your Kubernetes cluster is hosted, you might need to make other host-specific modifications or run other commands to accomplish the steps for configuring persistent storage, load-balancing, and external IP addresses.

To provide an optional method for completing this tutorial, the Kubernetes configuration files that are used in these steps are pre-configured to use a pre-built container image for the front-end of the guestbook app. The container image includes all the modifications described in the steps below and has been built and pushed to Google Container Registry at: `gcr.io/google-samples/steps-twotier:k8s`. This is explained below in [Step 1](#to-run-the-containerized-app-in-a-cluster).

If you want to save a version of your app that runs in Docker Engine, you should make a copy. Otherwise, the changes that you make in the steps below will modify the app so that it runs only in Kubernetes.

------------

## Prerequisites

You must meet the following prerequisites to port you containerized app into your Kubernetes cluster:

 * To port your containerized app into your Kubernetes, you must:

     * Download and install the Docker Engine. For details, see [Install Docker Engine](https://docs.docker.com/installation/).

     * Create an account in a registry where you can push your container images. An account in either [Docker Hub](https://hub.docker.com/), [Google Container Registry](https://cloud.google.com/tools/container-registry/), or another private registry is supported.

     * Understand the roles of the Kubernetes components in your cluster, including the replication controllers, pods, and services. For more information, see the [Kubernetes Overview](../../docs/user-guide/overview.md).

     * Install Kubernetes and then create and run a cluster in Google Compute Engine. For details, see [Creating a Kubernetes Cluster](../../docs/getting-started-guides/gce.md).

     * Install and configure the kubectl CLI. For details, see [Installing kubectl](../../docs/user-guide/prereqs.md).

 * To follow along step-by-step with porting the example guestbook app into a Kubernetes cluster on Google Cloud Platform, you must:

    * Have a copy of the containerized version of the example guestbook app:

        * If you performed the steps of [modifying the guestbook app to run in a container](../container/README.md), you can continue with the steps below and manually update the files that you have installed.

        * To start following along now, you can download a copy of the files.

            Download the following source files of the containerized version of the guestbook app to an installation directory from where you will modify the files and then build a new container:

            * [`Dockerfile`](../container/Dockerfile)
            * [`app.go`](../container/app.go)
            * [`main.html`](../container/main.html)

     * Create a Google Compute Engine project on Google Cloud Platform. For a trial, see [Google Cloud Platform Pricing](https://cloud.google.com/pricing/).

     * Install and configure the Google Cloud SDK. For details, see [Installation and Quick Start](https://cloud.google.com/sdk/#Quick_Start).

------------

## To run the containerized app in a cluster:

 1. Modify the front-end of the guestbook app (`app.go`), build the container image, and then push the image to a registry:

    > **Note**: If you are following along step-by-step with the guestbook example, you have the option to skip to the next step about creating Kubernetes configuration files. You should review the individual steps to learn how to modify your app, build a new container, and then push the image to a registry. But you have the option to continue following along by instead using the pre-configured front-end image that has been built and push to Google Container Registry at: `gcr.io/google-samples/steps-twotier:k8s`.

     1. Modify the following lines in the `app.go` file so that it discovers the `mysql` Kubernetes service through environment variables:

        ```go
        ...
        func connect() (*sql.DB, error) {
            dbpw := os.Getenv("DB_PW")
            connect := fmt.Sprintf("root:%v@tcp(mysql-hostname:3306)/?parseTime=true", dbpw)
            db, err := sql.Open("mysql", connect)
            if err != nil {
               return db, fmt.Errorf("Error opening db: %v", err)
            }
        ...
        ```

        1. Revise the following line to replace the hard-coded server host name and port information with the `%v:%v`, `mysqlHost`, and `mysqlPort` variables:

            `connect := fmt.Sprintf("root:%v@tcp(`~~`mysql-hostname:3306`~~`)/?parseTime=true", dbpw)`

            Result:

            `connect := fmt.Sprintf("root:%v@tcp(%v:%v)/?parseTime=true", dbpw, mysqlHost, mysqlPort)`

        1. Insert the following lines to use the `MYSQL_SERVICE_PORT` and `MYSQL_SERVICE_HOST` environment variables:

            ```go
            mysqlHost := os.Getenv("MYSQL_SERVICE_HOST")
            mysqlPort := os.Getenv("MYSQL_SERVICE_PORT")
            ```

        Result:

        ```go
        ...
        func connect() (*sql.DB, error) {
            dbpw := os.Getenv("DB_PW")
            mysqlHost := os.Getenv("MYSQL_SERVICE_HOST")
            mysqlPort := os.Getenv("MYSQL_SERVICE_PORT")
            connect := fmt.Sprintf("root:%v@tcp(%v:%v)/?parseTime=true", dbpw, mysqlHost, mysqlPort)
            db, err := sql.Open("mysql", connect)
            if err != nil {
                return db, fmt.Errorf("Error opening db: %v", err)
            }
        ...
        ```

     1. Build the container image for the front-end and then push the image to the registry.

        > **Remember**: You can skip this step and continue to follow along with the tutorial by downloading the front-end of the guestbook app that has already been pushed to Google Container Registry at: `gcr.io/google-samples/steps-twotier:k8s`.

        For a private container registry, you must refer to their documentation for details on how to push your container images. You can use the following Google Container Registry and Docker Hub examples for guidance:

        * For Google Container Registry, you use the following commands to build the container image with Docker Engine and then push the image to your project in Google Container Registry:

            ```
            docker build -t gcr.io/<project-id>/twotier .
            gcloud docker push gcr.io/<project-id>/twotier
            ```

            where `<project-id>` is the ID of your project in Google Container Registry. For details, see [Pushing to the registry](https://cloud.google.com/container-registry/docs/#pushing_to_the_registry).

        * For Docker Hub, you use the following commands to build the container image with Docker Engine and then push the image to your account in Docker Hub:

            ```
            docker build -t <account-name>/twotier .
            docker push <account-name>/twotier
            ```

            where `<account-name>` correspond to the name of your account in Docker Hub. For details, see [Pushing a repository image to Docker Hub](https://docs.docker.com/docker-hub/repos/#pushing-a-repository-image-to-docker-hub).

 1. Create the Kubernetes configuration files in the root directory of your guestbook app:

    1. To define the front-end container image, create a configuration file named `twotier.yaml` that includes the following definitions:

        > **Tip**: You can skip this step and instead download this pre-configured copy of the file that's ready to run in Kubernetes: [`twotier.yaml`](twotier.yaml).

        ```yaml
        ---
          kind: "ReplicationController"
          apiVersion: "v1"
          metadata:
            name: "twotier"
          spec:
            replicas: 2
            template:
              metadata:
                labels:
                  role: "front"
              spec:
                containers:
                - name: "twotier"
                  env:
                  - name: DB_PW
                    value: mysecretpassword
                  image: "gcr.io/google-samples/steps-twotier:k8s"
                  ports:
                  - name: "http-server"
                    hostPort: 80
                    containerPort: 8080
                    protocol: "TCP"
        ---
          kind: "Service"
          apiVersion: "v1"
          metadata:
            name: "twotier"
          spec:
            ports:
            - protocol: "TCP"
              port: 80
              targetPort: "http-server"
            selector:
              role: "front"
            type: "LoadBalancer"
        ```

        > **Remember**: The details above specify the image of the front-end container that has already been pushed to Google Container Registry at: `gcr.io/google-samples/steps-twotier:k8s`. If you pushed your image to a different project or container registry, you must edit the `image:` line, for example: `image: "`*`<container-registry-details>`*`/twotier"`.

        At a high-level, the `twotier.yaml` file defines the following notable Kubernetes components and details:

        * Replication controller:
            * Ensure that two pod replicas are always running
        * Pods:
            * The container image of the pre-configured guestbook app in Google Container Registry
            * Password environment variable `DB_PW`
        * Service named `twotier`:
            * Load balancer service type

    1. To define the back-end container, create a configuration file named `mysql.yaml` that includes the following definitions:

        > **Tip**: You can skip this step and instead download this pre-configured copy of the file that's ready to run in Kubernetes: [`mysql.yaml`](mysql.yaml).

        ```yaml
        ---
          kind: "ReplicationController"
          apiVersion: "v1"
          metadata:
            name: "mysql"
          spec:
            replicas: 1
            template:
              metadata:
                labels:
                  role: "mysql"
              spec:
                volumes:
                - name: "mysql-vol"
                  gcePersistentDisk:
                    pdName: "mysql-disk"
                    fsType: "ext4"
                containers:
                - name: "mysql"
                  image: "mysql:latest"
                  env:
                  - name: MYSQL_ROOT_PASSWORD
                    value: mysecretpassword
                  ports:
                  - name: "mysql"
                    containerPort: 3306
                    protocol: "TCP"
                  volumeMounts:
                  - name: "mysql-vol"
                    mountPath: "/var/lib/mysql"
        ---
          kind: "Service"
          apiVersion: "v1"
          metadata:
            name: "mysql"
          spec:
            ports:
            - protocol: "TCP"
              port: 3306
              targetPort: "mysql"
            selector:
              role: "mysql"
        ```

        At a high level, the `mysql.yaml` file defines the following notable Kubernetes components and details:

        * Replication controller:
            * Ensures that one pod is running; no replicas
        * Pod:
            * Volume for Google Compute Engine persistent disk storage
            * The publicly hosted `mysql` container image in Docker Hub
            * Password environment variable `MYSQL_ROOT_PASSWORD`
        * Service named `mysql`:
            * Service type `mysql`
            * Environment variables:
                * Host name (`MYSQL_SERVICE_HOST`)
                * Port number (`MYSQL_SERVICE_PORT`)

    > Extended learning: For more information about the Kubernetes labels, selectors, and other definitions in these configuration files, see the [Concepts guide](../../docs/user-guide/README.md#concept-guide) section in the User Guide overview.

 1. In the `mysql.yaml` configuration file that you just created, the following volume definition specifies the use of persistent disk storage in Google Compute Engine:

    ```
    ...
    spec:
      volumes:
      - name: "mysql-vol"
        gcePersistentDisk:
          pdName: "mysql-disk"
          fsType: "ext4"
    ...
    ```

    To create the physical disk and configure the persistent disk storage in Google Compute Engine, you run the following command from your terminal window:

    ```shell
    gcloud compute disks create --size=200GB mysql-disk
    ```

    A 200 GB Disk named `mysql-disk` is created in Google Compute Engine.

    > Extended learning: For more information about defining persistent disks and other types of storage, see the [volumes](../../docs/user-guide/volumes.md) topic.

 1. Deploy your containers to your Kubernetes cluster by running the following commands from your terminal window:

    ```shell
    kubectl create -f ./mysql.yaml
    kubectl create -f ./twotier.yaml
    ```

    Kubernetes creates the corresponding replication controllers, pods, and services based on your configuration files and runs your app in your cluster.

    > Extended learning: Now that your containerized app is running in the pods of your cluster, you can use the [Managing Deployed Applications](../../docs/user-guide/managing-deployments.md) topic to learn how to manage your deployed app.

 1. Open port 80 where you host your Kubernetes cluster to externalize the IP address of the `twotier` service.

    To open port 80 in Google Cloud Platform and expose the IP address, you run the following command from your terminal window:

    ```shell
    gcloud compute firewall-rules create k8s-80 --allow=tcp:80 --target-tags kubernetes-minion
    ```

    The firewall rule `k8s-80` is created for port 80 in your Google Cloud Platform project. You can view all of your filewall rules from in the [Google Developers Console](https://console.developers.google.com).

    > **Important**: Depending on your environment and where your Kubernetes cluster is hosted, you must enable and configure external load balancing. In Google Cloud Platform, Kubernetes creates forwarding rules for you when `type: "LoadBalancer"` is defined in your configuration files.

 1. View the guestbook app in your web browser:

    1. Retrieve the external IP address of the service by running the following `kubectl` command from the terminal window:

        ```shell
        kubectl describe service twotier
        ```

    1. Locate the value that is listed for `LoadBalancer Ingress` and then open your web browser to that IP address: `http://`*`<loadbalancer_ingress_ip_adddress>`*.

    Example: `http://103.104.105.106`

------------

## Summary

In this step, you ported the containerized version of the two-tier app into a Kubernetes cluster. You can continue to the next optional step to learn how to use Kubernetes secrets to secure and container your passwords.

------------

#### Previous: [Run apps in containers](../containers/README.md)

#### Next: [Extended learning: Using secrets for your passwords](secrets/README.md)

<!-- BEGIN MUNGE: GENERATED_ANALYTICS -->
[![Analytics](https://kubernetes-site.appspot.com/UA-36037335-10/GitHub/examples/porting-steps/k8s/README.md?pixel)]()
<!-- END MUNGE: GENERATED_ANALYTICS -->
