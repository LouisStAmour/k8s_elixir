export K8SLOCATION="westeurope"
export RGNAME="k8s"
export K8SCLUSTERNAME="chgeuerk8s"
export DNSPREFIX="${K8SCLUSTERNAME}"
export SSHPUBFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.public"
export SSHPRIVFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.private"

export sshkey=`cat $SSHPUBFILE`

PLAINTEXT_CREDS_FILE=/mnt/c/Users/chgeuer/azurecreds.json

export AZURE_PACKER_APPID=$(cat    $PLAINTEXT_CREDS_FILE | jq -r .AZURE_CLOUD.appId)
export AZURE_PACKER_PASSWORD=$(cat $PLAINTEXT_CREDS_FILE | jq -r .AZURE_CLOUD.password)
export AZURE_PACKER_TENANTID=$(cat $PLAINTEXT_CREDS_FILE | jq -r .AZURE_CLOUD.tenantId)
export AZURE_LINUX_PASSWORD=$(cat  $PLAINTEXT_CREDS_FILE | jq -r .AZURE_LINUX_PASSWORD)

export acr_name=chgeuerregistry2

# az acs kubernetes get-credentials --resource-group="${RGNAME}" --name="${K8SCLUSTERNAME}" --ssh-key-file="${SSHPRIVFILE}"

