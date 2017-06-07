# Kubernetes

- [Get started with a Kubernetes cluster in Container Service](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-walkthrough)

- Install Azure CLI 2.0: `pip install --user azure-cli` (as described  [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)) or update via `pip install --upgrade azure-cli && az cloud set --name AzureGermanCloud`

- Download kubctl: `curl -LO https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe` (as described [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
- Download kubctl: `curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/windows/amd64/kubectl.exe` (as described [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/))




## Azure Security Setup

- [Create an Azure service principal with Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

```
az cloud set --name AzureCloud
az login
az account set --subscription chgeuer-work
az ad app create --display-name "chgeuer-packer" --homepage "http://packer.geuer-pollmann.de/" --identifier-uris "http://packer.geuer-pollmann.de/" --key-type "Password" --password %AZURE_PACKER_PASSWORD%

az ad app list --display-name chgeuer-packer | jq .[0].appId
az ad sp create --id 8562e504-49dc-4d2f-a663-fabf7cf9368e

az role assignment list   --assignee 8562e504-49dc-4d2f-a663-fabf7cf9368e
az role assignment create --assignee 8562e504-49dc-4d2f-a663-fabf7cf9368e --role Contributor

REM Windows
az login --service-principal --tenant %AZURE_PACKER_TENANTID% --username %AZURE_PACKER_APPID% --password %AZURE_PACKER_PASSWORD%

# Linux
az login --service-principal --tenant $AZURE_PACKER_TENANTID --username $AZURE_PACKER_APPID --password $AZURE_PACKER_PASSWORD

az account set --subscription chgeuer-work

az ad sp reset-credentials --name %AZURE_PACKER_TENANTID% --password %AZURE_PACKER_PASSWORD%
```

## K8s cluster

### Windows

```
SET K8SLOCATION="westeurope"
SET RGNAME=k8s
SET K8SCLUSTERNAME=chgeuerk8s
SET DNSPREFIX="%K8SCLUSTERNAME%"
SET SSHPUBFILE="C:\Users\chgeuer\Java\keys\dcos.openssh.public"
SET SSHPRIVFILE="C:\Users\chgeuer\Java\keys\dcos.openssh.private"
SET /p sshkey=<"%SSHPUBFILE%"

az group create --name="%RGNAME%" --location=westeurope

az acs create --name="%K8SCLUSTERNAME%" --resource-group="%RGNAME%" --location="%K8SLOCATION%" --orchestrator-type=kubernetes --dns-prefix="%DNSPREFIX%" --ssh-key-value="%sshkey%" --service-principal="%AZURE_PACKER_APPID%" --client-secret="%AZURE_PACKER_PASSWORD%" --master-count=1 --agent-count=2 --agent-vm-size="Standard_DS1_v2" --admin-username="chgeuer" 
--admin-password="%AZURE_LINUX_PASSWORD%"

az acs kubernetes get-credentials --resource-group="%RGNAME%" --name="%K8SCLUSTERNAME%" --ssh-key-file="%SSHPRIVFILE%"
```

### Linux

```bash
K8SLOCATION="westeurope"
RGNAME="k8s"
K8SCLUSTERNAME="chgeuerk8s"
DNSPREFIX="${K8SCLUSTERNAME}"
SSHPUBFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.public"
SSHPRIVFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.private"

sshkey=`cat $SSHPUBFILE`

az group create --name="${RGNAME}" --location="${K8SLOCATION}"

az acs create --name="${K8SCLUSTERNAME}" --resource-group="${RGNAME}" --location="${K8SLOCATION}" --orchestrator-type=kubernetes --dns-prefix="${DNSPREFIX}" --ssh-key-value="${sshkey}" --service-principal="${AZURE_PACKER_APPID}" --client-secret="${AZURE_PACKER_PASSWORD}" --master-count=1 --agent-count=2 --agent-vm-size="Standard_DS1_v2" --admin-username="chgeuer" --admin-password="${AZURE_LINUX_PASSWORD}"

az acs kubernetes get-credentials --resource-group="${RGNAME}" --name="${K8SCLUSTERNAME}" --ssh-key-file="${SSHPRIVFILE}"
```

## ingress 

```
kubectl get ingress -o json | jq .items[0].status.loadBalancer.ingress[0].ip

ssh chgeuer@chgeuerk8s.westeurope.cloudapp.azure.com -i ~/chgeuer/Java/keys/dcos.openssh.private

ssh "chgeuer@${K8SCLUSTERNAME}.${K8SLOCATION}.cloudapp.azure.com" -i "${SSHPRIVFILE}"
```

```
REPLACE_OS_VARS=true PORT=4000 HOST=localhost SECRET_KEY_BASE=highlysecretkey ./_build/prod/rel/k8s_elix/bin/k8s_elix foreground
```

## Inject Azure Container Registry credential as [`imagePullSecret`](https://kubernetes.io/docs/concepts/containers/images/#referring-to-an-imagepullsecrets-on-a-pod) into K8s

```
K8SLOCATION="westeurope"
RGNAME="k8s"
K8SCLUSTERNAME="chgeuerk8s"
acr_name=chgeuerregistry1

# create a container registry
az acr create \
    --name="${acr_name}" \
    --resource-group="${RGNAME}" \
    --location="${K8SLOCATION}" \
    --sku="Basic" \
    --admin-enabled=true

# fetch ACS password from Azure
acr_pass=$(az acr credential show --name $acr_name | jq -r .passwords[0].value)

# inject imagePullSecret to k8s
kubectl create secret docker-registry "${acr_name}.azurecr.io" \
    --docker-server="https://${acr_name}.azurecr.io" \
    --docker-username="${acr_name}" \
    --docker-password="${acr_pass}" \
    --docker-email="root@${acr_name}"

# re-fetch password from k8s
acr_pass2=$( \
    kubectl get secret "${acr_name}.azurecr.io" --output=json | \
    jq -r '.data[".dockercfg"]' |  \
    base64 -d |  \
    jq -r ".[\"https://${acr_name}.azurecr.io\"].password" \
    )

# login docker to ACR
docker login "${acr_name}.azurecr.io" \
    --username $acr_name \
    --password $acr_pass
```

# Check imagePullSecret

- [Referring to `imagePullSecrets` on a Pod](https://kubernetes.io/docs/concepts/containers/images/#referring-to-an-imagepullsecrets-on-a-pod)

```yaml
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: jenkins-master
spec:
  replicas: 1
  template:
    metadata:
      name: jenkins-master
      labels:
        name: jenkins-master
    spec:
      containers:
      - name: elixir
        image: chgeuerregistry1.azurecr.io/chgeuer/elixir:1.4.4
        imagePullPolicy: Always
        readinessProbe:
          tcpSocket:
            port: 4000
          initialDelaySeconds: 20
          timeoutSeconds: 5
        ports:
        - name: web
          containerPort: 4000
      imagePullSecrets:
        - name: chgeuerregistry1
```

# An Elixir Dockerfile

```Dockerfile
FROM alpine:3.6

ENV ELIXIR_VERSION 1.4.4

RUN echo 'http://dl-4.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories && \
    apk --update add ncurses-libs \
                     erlang erlang-crypto erlang-syntax-tools erlang-parsetools \
                     erlang-inets erlang-ssl erlang-public-key erlang-eunit \
                     erlang-asn1 erlang-sasl erlang-erl-interface erlang-dev \
                     wget \
                     git && \
    apk --update add --virtual build-dependencies ca-certificates && \
    wget --no-check-certificate https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/Precompiled.zip && \
    mkdir -p /opt/elixir-${ELIXIR_VERSION}/ && \
    unzip Precompiled.zip -d /opt/elixir-${ELIXIR_VERSION}/ && \
    rm Precompiled.zip && \
    apk del build-dependencies && \
    rm -rf /etc/ssl && \
    rm -rf /var/cache/apk/*

ENV PATH $PATH:/opt/elixir-${ELIXIR_VERSION}/bin

RUN mix local.hex --force && \
    mix local.rebar --force

CMD ["/bin/sh"]
```

```
cd elixir
docker build .   -t "${acr_name}.azurecr.io/chgeuer/elixir:1.4.4"
docker push         "${acr_name}.azurecr.io/chgeuer/elixir:1.4.4"
docker run -it --rm "${acr_name}.azurecr.io/chgeuer/elixir:1.4.4" /bin/sh

cd ../src3
cp Dockerfile.build Dockerfile
docker build .   -t "${acr_name}.azurecr.io/chgeuer/app:1.0.0"
docker push         "${acr_name}.azurecr.io/chgeuer/app:1.0.0"
docker run -it --rm "${acr_name}.azurecr.io/chgeuer/app:1.0.0"

kubectl create -f rc.yml
```

# Elixir

```bash

mix phoenix.new k8s_elixir --no-brunch --no-ecto

cd src3

mix release.init

MIX_ENV=prod mix phoenix.digest

MIX_ENV=prod mix release --env=prod

REPLACE_OS_VARS=true PORT=4000 HOST=example.com SECRET_KEY_BASE=highlysecretkey ./_build/prod/rel/k8s_elixir/bin/k8s_elixir foreground
```


# Links

- [Deploying Istio on Azure Container Service](https://readon.ly/post/2017-05-25-deploy-istio-to-azure-container-service/)
- Elixir
    - [Elixir/Erlang Clustering in Kubernetes](http://bitwalker.org/posts/2016-08-04-clustering-in-kubernetes/)
    - [Clustering Elixir nodes on Kubernetes](https://substance.brpx.com/clustering-elixir-nodes-on-kubernetes-e85d0c26b0cf)
    - A Complete Guide to Deploying Elixir & Phoenix Applications on Kubernetes 
        - [Part 1: Setting up Distillery](https://blog.polyscribe.io/a-complete-guide-to-deploying-elixir-phoenix-applications-on-kubernetes-part-1-setting-up-d88b35b64dcd)
        - [Part 2: Docker and Minikube](https://blog.polyscribe.io/a-complete-guide-to-deploying-elixir-phoenix-applications-on-kubernetes-part-2-docker-and-81e934c3fceb)
        - [Part 3: Deploying to Kubernetes](https://blog.polyscribe.io/a-complete-guide-to-deploying-elixir-phoenix-applications-on-kubernetes-part-3-deploying-to-bd5b1fcbef87)
        - [Part 4: Secret Management](https://blog.polyscribe.io/a-complete-guide-to-deploying-elixir-phoenix-applications-on-kubernetes-part-4-secret-f851d575bdd1)
    - [Scheduling Your Kubernetes Pods With Elixir](https://deis.com/blog/2016/scheduling-your-kubernetes-pods-with-elixir/)
    - [Deploy your Elixir app with a minimal docker container using Alpine Linux and Exrm](https://medium.com/@rubas/deploy-your-elixir-app-with-a-minimal-docker-container-using-alpine-linux-and-exrm-b4e166f1802)
- MISC
    - http://blog.lwolf.org/post/how-to-deploy-ha-postgressql-cluster-on-kubernetes/
    - https://blog.docker.com/2013/07/how-to-use-your-own-registry/
    - https://docs.docker.com/engine/reference/builder/#notes-about-specifying-volumes
    - https://docs.docker.com/engine/reference/commandline/build/#git-repositories
    - https://kubernetes.io/docs/concepts/containers/images/#referring-to-an-imagepullsecrets-on-a-pod
    - https://kubernetes.io/docs/concepts/workloads/pods/pod/
    - https://medium.com/devoops-and-universe/your-very-own-private-docker-registry-for-kubernetes-cluster-on-azure-acr-ed6c9efdeb51
    - https://sgotti.me/post/stolon-introduction/
- Kubernetes Draft
    - https://www.noelbundick.com/2017/05/31/Draft-on-Azure-Container-Service/ 
- http://programminghistorian.org/lessons/json-and-jq

### Install helm

```
#install helm
curl -O curl -O https://dl.k8s.io/kubernetes-helm/helm-v2.4.2-linux-amd64.tar.gz
tar xvfz helm-v2.4.2-linux-amd64.tar.gz linux-amd64/helm -C /usr/local/bin

#install draft
curl -O https://azuredraft.blob.core.windows.net/draft/draft-canary-linux-amd64.tar.gz
tar -xzf draft-canary-linux-amd64.tar.gz
sudo mv linux-amd64/draft /usr/local/bin

DNS A RECORD: *.draft.geuer-pollmann.de --> 52.174.247.210


acr_name=chgeuerregistry1
draft_wildcard_domain=draft.geuer-pollmann.de


helm_cred=$(az acr credential show --name $acr_name | jq -M -c ". | { username: .username, password: .passwords[0].value, email: ([ \"root\", ([.username, \"azurecr.io\"] | join(\".\")) ] | join(\"@\"))}" | base64 -w 0)

draft init --set registry.url=$acr_name.azurecr.io,registry.org=draft,registry.authtoken=$helm_cred,basedomain=$draft_wildcard_domain


platformUpdateDomain=$(curl -G -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-03-01" | jq -r ".compute.platformUpdateDomain")

platformFaultDomain=$(curl -G -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-03-01" | jq -r ".compute.platformFaultDomain")
```

## minikube

```
minikube start --kubernetes-version="v1.6.4" --vm-driver="hyperv" --memory=1024 --hyperv-virtual-switch="minikube" --v=7 --alsologtostderr

kubectl --context="${K8SCLUSTERNAME}" get pods
kubectl --context=azure get pods
```

### potential network fixes

- https://www.shadowsplace.net/1242/windows/internet-connection-sharing-has-been-disabled-by-the-network-administrator-windows-8/
    - `gpedit.msc` --> Computer Configuration/Administrative Templates/Network/Network Connections
        - Disable *Prohibit installation and configuration of Network Bridge on your DNS domain network*
        - Disable *Prohibit use of Internet Connection Firewall on your DNS domain network*
        - Disable *Prohibit use of Internet Connection Sharing on your DNS domain network*
        - Disable *Require domain users to elevate when setting a network’s location*

```regedt32
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Network Connections]
"NC_ShowSharedAccessUI"=dword:00000000
"NC_PersonalFirewallConfig"=dword:00000001
```

