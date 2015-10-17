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
[here](http://releases.k8s.io/release-1.0/examples/porting-steps/secret/README.md).

Documentation for other releases can be found at
[releases.k8s.io](http://releases.k8s.io).
</strong>
--

<!-- END STRIP_FOR_RELEASE -->

<!-- END MUNGE: UNVERSIONED_WARNING -->

# Extended learning: Using secrets for your passwords

You use Kubernetes secrets as an alternative, flexible, and more secure method for managing the sensitive data that you use in your clusters.

In this step, the version of the containers of the two-tier guestbook app that you have running in your Kubernetes cluster is be modified to replace the environment variable that contains the MySQL server password with a Kubernetes secret.

In this optional step, the guestbook app and its container are modified to use Kubernetes secrets for storing your passwords. You create and use secrets as an alternative, safer, and more flexible method for using and storing passwords in your Kubernetes clusters. For more information about secrets, including other examples, see the [Secrets](../../docs/user-guide/secrets.md) topic.

To use secrets, you must define the secret itself and then update each pod in your cluster for which you want using that secret.

For the guestbook app, the environment variables that you created in the previous step are removed and replaced with a secret. Therefore, a configuration file must be created for the secret, the pod definitions must be updated, and the `Dockerfile` file of the MySQL container image must be modified.

#### Key learning points

 * How to create and use Kubernetes secrets, including:
    * How to push your secret to a private registry.
    * How to mount the secret in your containers.
 * How to use a custom `Dockerfile` with a hosted container image.

### Before you begin

If you performed the optional steps of locally installing the example app, you can manually update the files to follow along step-by-step. You can also download copies of that version of the app from:

    * [`mysql.yaml`](../k8s/mysql.yaml)
    * [`twotier.yaml`](../k8s/twotier.yaml)
    * [`Dockerfile`](../k8s/Dockerfile)
    * [`app.go`](../k8s/app.go)
    * [`main.html`](../k8s/main.html)

## To create and use secrets:


 add a file [`password.yaml`](secret/password.yaml) that defines the secret:

```yaml
apiVersion: "v1"
kind: "Secret"
metadata:
  name: "mysql-pw"
data:
  password: "bXlzZWNyZXRwYXNzd29yZA=="
```

Then we modify the pod definition of both the mysql and front end pods to remove the password environment variables, and add the volume mount definitions for the secret:

    * [`mysql.yaml`](mysql.yaml)

```yaml
--- k8s/mysql.yaml  2015-07-13 14:40:54.509756256 -0700
+++ secret/mysql.yaml   2015-07-13 14:32:16.259056145 -0700
@@ -15,12 +15,12 @@
           gcePersistentDisk:
             pdName: "mysql-disk"
             fsType: "ext4"
+        - name: "password"
+          secret:
+            secretName: "mysql-pw"
         containers:
         - name: "mysql"
-          image: "mysql:latest"
-          env:
-          - name: MYSQL_ROOT_PASSWORD
-            value: mysecretpassword
+          image: "gcr.io/google-samples/mysql:secret"
           ports:
           - name: "mysql"
             containerPort: 3306
@@ -28,6 +28,9 @@
           volumeMounts:
           - name: "mysql-vol"
             mountPath: "/var/lib/mysql"
+          - name: "password"
+            mountPath: "/etc/mysql-password"
+            readOnly: true
```

    * [`twotier.yaml`](twotier.yaml)

```yaml
--- k8s/twotier.yaml    2015-07-13 14:42:19.875519381 -0700
+++ secret/twotier.yaml 2015-07-13 14:32:17.711086045 -0700
@@ -10,17 +10,22 @@
         labels:
           role: "front"
       spec:
+        volumes:
+        - name: "password"
+          secret:
+            secretName: "mysql-pw"
         containers:
         - name: "twotier"
-          env:
-          - name: DB_PW
-            value: mysecretpassword
-          image: "gcr.io/google-samples/steps-twotier:k8s"
+          image: "gcr.io/google-samples/steps-twotier:secret"
           ports:
           - name: "http-server"
             hostPort: 80
             containerPort: 8080
             protocol: "TCP"
+          volumeMounts:
+          - name: "password"
+            mountPath: "/etc/mysql-password"
+            readOnly: true
```

We then modify our app to read the password from the mounted file, instead of the environment variable:


    * [`app.go`](app.go)

```go
--- k8s/app.go  2015-05-14 15:22:51.851319468 -0700
+++ secret/app.go   2015-05-15 14:32:31.111850594 -0700
@@ -4,6 +4,7 @@
    "database/sql"
    "fmt"
    "html/template"
+   "io/ioutil"
    "log"
    "net/http"
    "os"
@@ -13,10 +14,13 @@
 )
 
 func connect() (*sql.DB, error) {
-   dbpw := os.Getenv("DB_PW")
+   dbpw, err := ioutil.ReadFile("/etc/mysql-password/password")
+   if err != nil {
+       return nil, fmt.Errorf("Error reading db password: %v", err)
+   }
    mysqlHost := os.Getenv("MYSQL_SERVICE_HOST")
    mysqlPort := os.Getenv("MYSQL_SERVICE_PORT")
-   connect := fmt.Sprintf("root:%v@tcp(%v:%v)/?parseTime=true", dbpw, mysqlHost, mysqlPort)
+   connect := fmt.Sprintf("root:%v@tcp(%v:%v)/?parseTime=true", string(dbpw), mysqlHost, mysqlPort)
    db, err := sql.Open("mysql", connect)
    if err != nil {
        return db, fmt.Errorf("Error opening db: %v", err)
```

For the mysql container, it is a bit trickier. We used the public mysql image, but we need to tweak it to read the password from a file. For this we add a new [`mysql/Dockerfile`](secret/mysql/Dockerfile) that contains:

```
FROM mysql:latest
CMD export MYSQL_ROOT_PASSWORD=$(cat /etc/mysql-password/password); /entrypoint.sh mysqld
```

We are setting the password variable on the `CMD` line of the Dockerfile, which gets evaluated at runtime. We then run the command from the [original Dockerfile](https://github.com/docker-library/mysql/blob/master/5.6/Dockerfile). Now we use our customized mysql image, instead of the public image.


Build and push to a registry
----------------------------
For normal development, you would need to do this step. For this step, the sample app has been pre-built and pushed to [Google Container Registry](https://cloud.google.com/tools/container-registry/) at `gcr.io/google-samples/steps-twotier:secret` and `gcr.io/google-samples/mysql:secret`. Therefore, you may skip to the next step if you wish

Install and configure [Docker](https://docs.docker.com/installation/).

You may use any Docker registry you wish, these steps demonstrate pushing to [GCR](https://cloud.google.com/tools/container-registry/). Follow the linked steps to setup the gcloud tool, then build and push:

```
docker build -t gcr.io/<project-id>/twotier .
gcloud  docker push gcr.io/<project-id>/twotier
cd mysql
docker build -t gcr.io/<project-id>/mysql .
gcloud  docker push gcr.io/<project-id>/mysql
cd ..
```

**Source files directory**: [`secret`](../secret/)

Edit [`twotier.yaml`](twotier.yaml) and [`mysql.yaml`](mysql.yaml) and change the `image:` line to point to the containers you pushed to your registry.

Prep the Persistent Disk
-------
Here we are using Google Compute Engine persistent disks for the mysql server storage, see the [volumes documentation](https://github.com/docs/volumes.md) for other options. Check the `volumes:` section in [`mysql.yaml`](mysql.yaml) for how this is configured.

Create the physical disk:

```
gcloud compute disks create --size=200GB mysql-disk
```

Start up your pods on Kubernetes
------------
Have a kuberenetes cluster running, with working kubectl. [Getting Started](https://github.com/docs/getting-started-guides)

Edit [`password.yaml`](password.yaml) and set your own password. The secrets need to be base64 encoded, so you may wish to get this value with a command like `echo -n supersecret | base64`.
> Note: if you are reusing the persistent disk and database from the
  previous example, re-running the container with a new password will
  not change the password of the already created database.

```
kubectl create -f ./password.yaml
kubectl create -f ./mysql.yaml
kubectl create -f ./twotier.yaml
```

Open port 80 in your Kubernetes environment. On GCE you may run:

```
gcloud compute firewall-rules create k8s-80 --allow=tcp:80 --target-tags kubernetes-minion
```

Check it out
------------

```
kubectl describe service twotier
```

Look for `LoadBalancer Ingress` for the external IP of your
service. If your environment does not support external load balancers,
you will have to find the external IPs of your Kubernetes nodes.

In your browser, go to `http://<ip>`

STOP OR DELETE TO TEAR DOWN components:

docs/user-guide/kubectl/kubectl_delete
docs/user-guide/kubectl/kubectl_stop

## Next steps:

Learn how to administer your applications and clusters in Kubernetes:

 * [Kubernetes User Guide: Managing Applications](../../../docs/user-guide/README.md)
 * [Kubernetes Cluster Admin Guide](../../../docs/admin/introduction.md)

------------

## Summary

In this step, you upgraded the two-tier app that you have running in a Kubernetes cluster to use secrets. From here, the next step is to learn how to administer your apps and cluster.

------------

#### Previous: [Run your containerized apps in a Kubernetes cluster](../k8s/README.md)

#### Next (*Administering your apps and Kubernetes clusters*):

 * [User Guide: Managing Applications](../../../docs/user-guide/README.md)
 * [Cluster Admin Guide](../../../docs/admin/introduction.md)

<!-- BEGIN MUNGE: GENERATED_ANALYTICS -->
[![Analytics](https://kubernetes-site.appspot.com/UA-36037335-10/GitHub/examples/porting-steps/secret/README.md?pixel)]()
<!-- END MUNGE: GENERATED_ANALYTICS -->
