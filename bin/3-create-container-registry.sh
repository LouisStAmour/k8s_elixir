
acr_name=chgeuerregistry1

az acr create \
    --name="${acr_name}" \
    --resource-group="${RGNAME}" \
    --location="${K8SLOCATION}" \
    --sku=Basic \
    --admin-enabled=true
  
