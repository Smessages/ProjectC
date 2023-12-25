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
![Alt text](/screenshots/cluster-created.png?raw=true "cluster created")
```
## Cluster Setup

- step 1

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
![Alt text](/screenshots/set-aroon-nfs-default.png?raw=true "edit to default storageClass")
![Alt text](/screenshots/edit-scLass.png?raw=true "change the default sc")


- step 2 nodes configurations

Now that we have traefik install and running we need to make sure that all the nodes in the cluster have docker installed
becuase jenkins user will be running some containers inside the pods on the cluster using the underlying docker socket on each node the pod will be runnig on.

in this project we wrote an ansible playbook that will configure all the cluster nodes with docker and will expose the docker api , also the playbook will create a user jenkins with a home directory, create an ssh key pair for this user make him part of the docker group so that he can run docker commands , the playbook also install some few dependencies.

on successfull installation , you should have smething like this..
![Alt text](/screenshots/ansible-config.png?raw=true "ansible config nodes")

-step 3 jenkins deployment

we will deploy jenkins pod  in the cluster and we will set it to run our builds and test for our aplications.
to access jenkins web interface for the configurations we will create an ingress to make it available out of the cluster so that we can access it throught our web browser.

The jenkins deployment is accessible  in the jenkins directory 
inside the directory we have a deployment.yaml file whcich basicaly create the jenkins deployment in a specific NS(namespace), we specify the service seviceAccount in the spec very important this will help us bind a role to the user jenkins with the secessary permissions for all the jobs we will be doing.

we also expose the deployment in the service definition  in the same namespace.

notice the claim we created at the begining of the file that we mentioned in the volumes section of the deployment which storageClassName is aroon-nfs the one we set earlier. 
we also heve a file named service-account.yaml that creates also a bunch of resources , it creates:
- serviceAccount named jenkins-admin in the namespace ops
- role named jenkins in the same namespace
- roleBinding that bind the role jenkins to the serviceAccount previously mentioned in the jenkins deployment . we also include the namespace in the subject of the rolebinding

![Alt text](screenshots/roleBinding.png?raw=true "role binding")

The commands to issue in this directory are:

- 1- kubectl create -f service-account.yaml
- 2- kubectl create -f deployment.yaml

after we should see this :

![Alt text](/screenshots/jenkins-deployment.png?raw=true "jenkins deployment")

Now that our jenkins pod is up and running we can access it in our web browser , but before we can do that, i would like to show you the nodes configurations with docker and the ingress we need to create to be able to access jenkins in the web browser. 

- Nodes configuration 
lets ssh into one of our cluster node and check the docker service status.

![Alt text](/screenshots/status-docker-on-worker-nodes.png?raw=true "docker on worker nodes")

here the configuration is showing clear how jenkins wil be able to access the docker daemon using the host socket 
we will also take the ssh private_key and pub_key we created during the ansible configuration . These will hepl the user jenkins to to connect to the hostduring the jobs he will be doing.
These key pair will also be set in our github repo for the same purpose.

- creation of the ingress jenkins

Since we are working with traefik as our default ingress controller , we need to tell traefik to send all the incoming request related to jenkins to the right service and port .
here is the description of the jenkins service we created earlier.

![Alt text](/screenshots/description-jenkins-service.png?raw=true "jenkins service description")

the command to create an ingress for this service will be 
```
kubectl create ing jenkins --rule=jenkins-service.digbot.fun/*=jenkins-service:8080

```

the picture below shows that the ingress is created and we can see the enpoint

![Alt text](/screenshots/describe-ingress.png?raw=true "ingress description")

this allow us to access the jenkins server web interface.

Notice how traefik behind the scene is load-balancing the incoming trafic in the cluster , we can litteraly redirect any trafic using our traefik ingress-controller and also secure our endpoints services whenever is needed. 

With all this set up we can configure our jenkins pipeline.


## Jenkins Pipeline Setup

We need to get the password for login into the jenkins server web interface

we can get it using this method for simplicity 
```
kubectl logs <jenkins pod>
```
![Alt text](/screenshots/passloginjenkins.png?raw=true "pass login jenkins")

The setup is pretty straight forward  .

- 1: we will configure the necessary credentials

- 2: we will download the necessary plugins

- 3: configure the workers 

- 4: create the pipeline

- 5: run the pipeline

I will just screenshot each steps for the sake of brievity and i will explain the details of each steps during the presentation if needed

the pipeline screenshot already shows that our images were built correctly, and we actualy have our images on the docker repository we can mentioned those images in a kuberntes deployment as we did for other deployment and that's how we will deploy our application on cloud.

we will expose our deployment as service in the cluster and same as the we expose the jenkins deployment we will also create an ingress to make our application available out of the cluster with the help of traefik ingress controller.


The steps are pretty simple

- we create the deployments with the images we just built
- we expose the deployment 
- we create an ingress 
- we access our applications in the web browser

little refresh just to give a little bit of context about the application we are building,

Marketplace as you could guess from the name is marketplace app(microservice) that will be communicating wwith another microservice which in our project is called Recommendattions(microservice) .

the Recommendation microservice is making recommendations on products, a user browsing on the marketplace, would like to buy. 

the recommendations app is using a grpc protocol to interact with the marketplace microservice.

GRPC is another way to make microservices talk to each other it is more robust and offer some great advantages uppon rest api request. 
checkout the Recommendations and the marketplace code in those directories to see how the code where generated using a single one line commande both on the server and client side.

i will leave the link to the documentation about the grpc protocol that help me prepare this project.

lets create our ingress for the marketplace service because the recommendation service don't need to be accessible by the user , and for brievity of the presentation we just implement a bookstore in the marketplace app and a recommendation microservice that will be sending some recommendations base on the user connected to the marketplace.
The main purpose here in the application section is to show how this two microservices can communicate together using the gRPC proto.

- DEMO

The last thing i want to show in this project is to use cert-manager to add tls certificates to our ingresses

For that we ar going to use helm charts again for convinience to install cert-manager on our cluster

here is the commande to issue:

```
helm upgrade --install cert-manager cert-manager/cert-manager --version 1.13.2 \
  --create-namespace --namespace cert-manager \
  --set installCRDs=true

```
So same as with traefik charts we install early inthis project , this command will create a repo named cert-manager , update the chart if it already exist if not it will install it , then we want a namespace also to be created where we will install all the resources created by this command, we also set the installCRDs to true in case we want to use a spcific ISSUER forn our certificates.

Some few steps are to be done before we can start taking advantage of cert-manager in ou cluster. 

first thing we need an ISSUER which could be cluster wide or namespaced

we will be using letsencrypt for our project

the code below shows the ISSUER definition  which a kind ClusterIssuer and we want a production grade certificate from letsencrypt.

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: alindou@thenuumfactory.fr
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: issuer-letsencrypt-production
    # Add a single challenge solver, HTTP01 using traefik
    solvers:
    - http01:
        ingress:
          ingressClassName: traefik



```
second resource we need i the certificate for the endpoint we want to secure with tls cert.

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: marketplace.digbot.fun
spec:
  secretName: marketplace.digbot.fun
  dnsNames:
  - marketplace.digbot.fun
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer

```
this code request a certificate from letsencrypt for our marketplace endpoint  and if the verification went sucessfully we will be able to access our endpoint in a secure session with https://marketplace.digbot.fun


after the creation of the certificate , lets modify the ingress to take into account the new certificate generated with cert-manager.

for that we just have to edit the ingress resource and add a tls section in it. like as shown in the screenshot, otherwise we could delete the existing one and create a new ingress for the marketplace service

basically to provide a certificate to an ingress inside our cluster we have to do two things if the ingress already exist.
- 1: edit the existing ingress to add the tls section in his definition
Note: at this point if you try to connect to the marketplace app you will have and error with the default traefik certificate cuz the secretName mentioned in the ingress definition does not exist yet , so by default traefik will fill it with his own certificate and since your browser does'nt recognize the traefik certificate.

- 2: annotate the ingress with cert-manager.io/cluster-issuer=<YOUR_CLUSTER_ISSUER>
the command for our project will look like this 
```
kubectl annotate ing marketplace cert-manager.io/cluster-issuer=letsencrypt-production

```
this command tell cert-manager to obtain the missing certificate for the domain(host parameter in the tls section) we define ingress 

and based on that traefik will notice the new certificate and update the ingress with it.