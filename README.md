# ProjectC
Deploy an application on cloud
## setup of the kubeernetes cluster

we are going to set a kubernetes cluster with terraform and do the necessary confugutions on all the nodes for our applications and
services to function correctly.
in this project we will deploy in the cluster a jenkins deployment that will build our images applications and push them on the dockerhub
we will then be able to create a deployment calling the images built throught our jenkins plipeline.

## Cluster installation
### prerequisite

**Before starting , make sure you have the following installed
- Terraform
- Kubectl
- AWS cli, 
- AWS credentials with the necessary permissions  and roles correctly set
- helm (package manager)

## Usage

The cluster installation is pretty straight forward , just clone the repo source code , and  CD into the root directory , once you are in the root directory , just issue these commands in the right order. 
- terraform init (after successfull initialisation)
- terraform plan 
- terraform apply -auto-approve

All the resources this last command are going to create are describe in the main.tf file in the terraform directory 

these three commands wil create our cluster in few minutes .

on succesfull completion you should see something like this:
```
capture creation of the cluster

```
## Cluster Setup

Once our cluster is up and running we can start adding some few packages and configurations to it . So lets do that!!!
we will be traefik as our cluster ingress controller, an NFS as our default StorageClass in the cluster , we will also need ansible on our development machine to help in configuring the cluster nodes for the purpose of this project.

### Using helm package manager

- For installing traefik 
here is the command we use:

helm upgrade --install traefik traefik/traefik \
    --create-namespace --namespace traefik \
    --set "ports.websecure.tls.enabled=true" \
    --set "providers.kubernetesIngress.publishedService.enabled=true"

If need some more details about traefik i will add the link at the end of this document for your reference and all the other tools i will using during this project.

so basically this command create a NS called traefik , install the chart traefik on the cluster we've just created, if it already not exits, and if it exist then it will just upgrade it. Another things this command does and not least behind scene  , it create a repo named traefik where the chart will be install on my local machine , and set a websecure entrypoint(--set "ports.websecure.tls.enabled=true") , and since we want to use traefik as our default ingress in the cluster, we added the annotation (--set "ports.websecure.tls.enabled=true") to our command .

As you can see these few lines command do a lot in our cluster.

- For the NFS file system 
we are using a deployment  that you can find in the NFS-StorageClass directory , it will help us manage our volumes  and claims  while deploying our applications.

Once the NFS deployment is up and running some few configurations are yet to be done because when we create our cluster it comes with a default storageClass (gp2) , so we have to change that setting by editing the SC as shown in the screenshoot
![Alt text](/screenshots/set-aroon-nfs-default.PNG?raw=true "edit to default storageClass")
![Alt text](/screenshots/edit-scLass.png?raw=true "change the default sc")





