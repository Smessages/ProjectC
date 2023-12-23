# ProjectC
Deploy an application on cloud
## setup of the kubeernetes cluster

we are going to set a kubernetes cluster with terraform and do the necessary confugutions on all the nodes for our applications and
services to function correctly.
in this project we will deploy in the cluster a jenkins deployment that will build our images applications and push them on the dockerhub
we will then be able to create a deployment calling the images built throught our jenkins plipeline.

## Cluster installation
### prerequisite
Terraform
Kubectl
AWS cli, 
AWS credentials with the necessary permissions  and roles

The cluster installation is pretty straight forward , just clone the repo source code , and  CD into the root directory , once you are in the root directory , just issue these commands in the right order. 
1- terraform init (after successfull initialisation)
2- terraform plan 
3- terraform apply -auto-approve

these three commands wil create our cluster in few minutes .
