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
[here](http://releases.k8s.io/release-1.0/docs/user-guide/kubeconfig-file.md).

Documentation for other releases can be found at
[releases.k8s.io](http://releases.k8s.io).
</strong>
--

<!-- END STRIP_FOR_RELEASE -->

<!-- END MUNGE: UNVERSIONED_WARNING -->

# kubeconfig files

Authentication across Kubernetes can differ, for example:

- A running kubelet might have one way of authenticating (i.e. certificates).
- Users might all use a different way of authenticating (i.e. tokens).
- Administrators might provide individual certificates to users. 
- For multiple clusters, they might be all defined in a single file that provides users with the ability to use their own certificates. This also has the benefit of simplified global configuration that's shared across all clusters.

In order to accommodate switching between multiple clusters and supporting the varying number of users and their different methods of authentication, Kubernetes uses a kubeconfig file.

The *kubeconfig file* contains a series of authentication mechanisms for both users and clusters. The file contains tuples of user authentication and cluster connection information that the Kubernetes api-server uses to establish connections. Information for users and clusters are defined under the respective `users` and `clusters` sections. There is also a `contexts` section that defines nicknames for the associated namespaces, clusters, and users.

You can create and use multiple kubeconfig files in your clusters. At runtime the kubeconfig files are loaded and merged together using the override options that you specify. See the [Loading and merging rules](#loading_and_merging_rules) below for more information.

####Table of contents:

- [Example kubeconfig file](#example-kubeconfig-file)
- [Loading and merging rules](#loading-and-merging-rules)
- [Updating the kubeconfig file with `kubectl config`](#updating-the-kubeconfig-file-with-kubectl-config)
- [Related discussion](#related-discussion)


## Example kubeconfig file

Lets walk through a few key details in the following example kubeconfig file to help you understand its contents and structure:

 - In this example, the `current-context` option is specified with value `federal-context`. When the `current-context` option is used, by default, all clients that connect to any of the clusters defined in this file use the `federal-context` context.

 - The `federal-context` context specifies `green-user` as the default user. Therefore, any client with the correct certificates that connects to the api-server will be logged in as the green-user because those credentials are specified in the file.  
In contrast to the green-user who provides a certificate, the blue-user must provide a token to connect.

 - This kubeconfig file corresponds to a Kubernetes api-server that was launched with the `kube-apiserver --token-auth-file=tokens.csv` option, where tokens.csv contains:  
   ```
   blue-user,blue-user,1
   mister-red,mister-red,2
   ```  
Note that because each user authenticates using different methods, this api-server was launched with other options in addition to `--token-auth-file`. It is important to understand the different options that you can run in order to implement the authentication schemes. You should run only the options for the authentication methods that align with your security requirements and policies.

```yaml
current-context: federal-context
apiVersion: v1
clusters:
- cluster:
    api-version: v1
    server: http://cow.org:8080
  name: cow-cluster
- cluster:
    certificate-authority: path/to/my/cafile
    server: https://horse.org:4443
  name: horse-cluster
- cluster:
    insecure-skip-tls-verify: true
    server: https://pig.org:443
  name: pig-cluster
contexts:
- context:
    cluster: horse-cluster
    namespace: chisel-ns
    user: green-user
  name: federal-context
- context:
    cluster: pig-cluster
    namespace: saw-ns
    user: black-user
  name: queen-anne-context
kind: Config
preferences:
  colors: true
users:
- name: blue-user
  user:
    token: blue-token
- name: green-user
  user:
    client-certificate: path/to/my/client/cert
    client-key: path/to/my/client/key
```

As you can see, a kubeconfig file can contain more information than what’s necessary for a single session, including details for several clusters, users, and contexts.

For more information about kube-apiserver options, see [kube-apiserver](../admin/kube-apiserver.md).

### Manually creating kubeconfig files

You can easily use the above example as a template for creating your own kubeconfig files. See the [Commands to create our example file](#commands-to-create-our-example-file) section below to re-create this example on your computer.

Remember: Creating a cluster by running `kube-up.sh` creates a kubeconfig file for you. See [Creating a Kubernetes Cluster](../getting-started-guides/README.md) for information about getting started with `kube-up.sh`. 

## Loading and merging rules

Your kubeconfig files get loaded and merged based on the commands that you run from the terminal and the information specified in each kubeconfig file.

The following loading and merging rules are ordered by their priority:

 1. Retrieve the kubeconfig files from disk using the following hierarchy and merge rules:
   1. If the `CommandLineLocation` (the value of the `kubeconfig` command line option) is set, then use this file only and do not merge any other kubeconfig files. Only one instance of this flag is allowed in your kubeconfig files.
   1. If `EnvVarLocation` (the value of $KUBECONFIG) is available, then use it to define all of the files that will be merged.
   1. Merge the files using the following rules:  
      * Empty filenames are ignored. Note: Files with non-deserializable content cause errors.
      * The first time that a particular value or map key is found, then use that value or map key and ignore any subsequent occurrences.  
        For example, if a file sets `CurrentContext` for the first time, then the context in that file is preserved and any other files that also set `CurrentContext` are ignored. Another example is if two files specify a `red-user`, then only the values from the first file's red-user are used. Even non-conflicting entries from the second file's red-user are ignored and not merged into the final kubeconfig file.
      * If only a single kubeconfig file exists, then skip merging and use the file in `HomeDirectoryLocation` (~/.kube/config).
 1. Determine what context to use based on the following priorities:
   1. Command line argument (kubectl config): Use the value specified for `context`.
   1. Kubeconfig file: Use the value specified for `current-context`.
   1. Set no context if the values are undefined.
 1. Determine what user and cluster information to use based on the following priorities:  
    Note: At this point, the context might be undefined. Also, this check runs twice, once for user and then again for cluster.
   1. Command line argument (kubectl config): Use the value specified for `user` and `cluster`.
   1. Kubeconfig file: If `context` is specified, then use the value in the nested `cluster`.
   1. Set no user and cluster if the values are undefined.
 1. Determine the details of the cluster based on the following priorities:  
    Note: At this point, the cluster might be undefined. Also, value of the first instance found for a cluster attribute is used and all subsequent values are ignored.
   1. Command line argument (kubectl config): Use the values specified for `server`, `api-version`, `certificate-authority`, and `insecure-skip-tls-verify`.
   1. Kubeconfig file: Use the values specified in `cluster`.
   1. Ensure that a value for `server` is defined, otherwise throw an error.
 1. Determine the details of the user based on the following priorities:  
    Note: The value of the first instance found for a user attribute is used and all subsequent values are ignored.
   1. Command line argument (kubectl config): Use the values specified for `client-certificate`, `client-key`, `username`, `password`, and `token`.
   1. Kubeconfig file: Use the values specified in `user`.
   1. Ensure only a single authentication method is defined, otherwise throw an error.
 1. For any required information that's missing, either use default values or prompt the user for authentication information.

## Updating the kubeconfig file with `kubectl config`

To easily add, update, or remove details from your kubeconfig files, you can use the `kubectl config` *`subcommand`* commands. See [kubectl/kubectl_config.md](kubectl/kubectl_config.md) for details about all the commands.

### Examples

If you run the following commands from the terminal on a computer where a kubeconfig file does not exist:

```console
$ kubectl config set-credentials myself --username=admin --password=secret
$ kubectl config set-cluster local-server --server=http://localhost:8080
$ kubectl config set-context default-context --cluster=local-server --user=myself
$ kubectl config use-context default-context
$ kubectl config set contexts.default-context.namespace the-right-prefix
```

You can then run `$ kubectl config view` to display that configuration information:

```yaml
apiVersion: v1
clusters:
- cluster:
    server: http://localhost:8080
  name: local-server
contexts:
- context:
    cluster: local-server
    namespace: the-right-prefix
    user: myself
  name: default-context
current-context: default-context
kind: Config
preferences: {}
users:
- name: myself
  user:
    password: secret
    username: admin
```

And if you view the actual kubeconfig file, you will see that it contains the same details:

```yaml
apiVersion: v1
clusters:
- cluster:
    server: http://localhost:8080
  name: local-server
contexts:
- context:
    cluster: local-server
    namespace: the-right-prefix
    user: myself
  name: default-context
current-context: default-context
kind: Config
preferences: {}
users:
- name: myself
  user:
    password: secret
    username: admin
```

#### Commands to create our example file

To re-create the example kubeconfig file that we used in this help topic, you can run the following commands from your terminal:

Tip: To generate a kubeconfig file for your cluster, revise the command options so that they include details about your clusters api-server endpoints.

```console
$ kubectl config set preferences.colors true
$ kubectl config set-cluster cow-cluster --server=http://cow.org:8080 --api-version=v1
$ kubectl config set-cluster horse-cluster --server=https://horse.org:4443 --certificate-authority=path/to/my/cafile
$ kubectl config set-cluster pig-cluster --server=https://pig.org:443 --insecure-skip-tls-verify=true
$ kubectl config set-credentials blue-user --token=blue-token
$ kubectl config set-credentials green-user --client-certificate=path/to/my/client/cert --client-key=path/to/my/client/key
$ kubectl config set-context queen-anne-context --cluster=pig-cluster --user=black-user --namespace=saw-ns
$ kubectl config set-context federal-context --cluster=horse-cluster --user=green-user --namespace=chisel-ns
$ kubectl config use-context federal-context
```

Remember: More information about the `kubectl config` commands, is available in the [kubectl_config](kubectl/kubectl_config.md) topic. 

### Key points to remember

A few important points to keep in mind when creating or configuring your kubeconfig file:

- Before you design a kubeconfig file for convenient authentication, take a good look and really understand how your api-server is being launched to ensure that you meet your security requirements and policies.

- Make sure that your api-server is launched so that at least one user's credentials are defined in it. For example, see our "green-user" in the example above. Review the [Authentication](../admin/authentication.md) topic to better understand how to set up user authentication.

## Related discussion

For in-depth design discussion and to determine if change is in the pipeline, you can review http://issue.k8s.io/1755.

##### Related information

- [Authentication](../admin/authentication.md)
- [kube-apiserver](../admin/kube-apiserver.md)
- [Sharing cluster access](../user-guide/sharing-clusters.md)
- [kubectl_config](kubectl/kubectl_config.md)


<!-- BEGIN MUNGE: GENERATED_ANALYTICS -->
[![Analytics](https://kubernetes-site.appspot.com/UA-36037335-10/GitHub/docs/user-guide/kubeconfig-file.md?pixel)]()
<!-- END MUNGE: GENERATED_ANALYTICS -->

