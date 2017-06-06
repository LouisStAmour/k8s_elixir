export K8SLOCATION="westeurope"
export RGNAME="k8s"
export K8SCLUSTERNAME="chgeuerk8s"
export DNSPREFIX="${K8SCLUSTERNAME}"
export SSHPUBFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.public"
export SSHPRIVFILE="/mnt/c/Users/chgeuer/Java/keys/dcos.openssh.private"

export sshkey=`cat $SSHPUBFILE`

export acr_name=chgeuerregistry1
