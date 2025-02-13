

# OpenShift Pipelines Installation / Configuration for Devtools AI Sample Applications.
![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square)

A Helm chart for installing the OpenShift Pipelines Operator, ensuring requisite features for our samples are enabled, as well as providing GitHub Application credentials to Pipelines As Code.

This repo is a Helm chart that a user with Cluster Admin level privileges would run to set up OpenShift Pipelines for the Devtools AI sample applications. For more information about helm charts see the official [Helm Charts Documentation](https://helm.sh/).

## Requirements

- You have sufficient permissions to install operators on an OCP cluster.
- You have sufficient permissions to create a namespace whose name starts with "openshift-".
- You have sufficient permissions to create RBAC and ServiceAccounts in that namespace.

## Background

The chart first installs the [Openshift Pipelines Operator](https://www.redhat.com/en/technologies/cloud-computing/openshift/pipelines) and once Pipelines is up and running, ensures the Tekton Pipelines features needed by the sample AI applications are turned on.

Lastly, it will set up the Pipelines As Code component of OpenShift Pipelines with the credentials you provide in your `values.yaml` file that allow for interaction with your GitHub Application and the events it submits when you interact with your application's
GitHub repository.

## Installation

The helm chart can be directly installed from the OpenShift Dev Console. Check [here](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/building_applications/working-with-helm-charts#understanding-helm) for more information.

### Install using Helm

To install the Pipeline Install Helm chart using Helm directly, you can run:

```
helm upgrade --install <release-name> --namespace openshift-pipelines --create-namespace .
```

The `.gitignore` file in this repository filters files named `private-values.yaml`. Thus, you can maintain in
your local fork of this repository a value settings file outside of git management. Copy `values.yaml` in this directory to `private-values.yaml` and make any necessary edits to `private-values.yaml`. Then change your helm invocation to the following:

```shell
helm upgrade --install <release-name> --namespace openshift-pipelines --create-namespace -f ./private-values.yaml .
```

Below is a table of each value used to configure this chart. Note:

- Your helm release's name will be used to as a prefix for the `Subscription` instance used to initiate the install of OpenShift Pipelines.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tekton.gitAppId | string | `"<your github application ID"` | [REQUIRED] The GitHub Application ID |
| tekton.gitAppPrivateKey | string | `"< your multi-line and encoded github application private key >"` | [REQUIRED] The GitHub Application Private Key |
| tekton.gitAppWebhookSecret | string | `"<your github application webhook secret>"` | [REQUIRED] The GitHub Application Webhook Secret |

