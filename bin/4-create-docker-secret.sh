

acr_pass=$(az acr credential show --name $acr_name | jq -r .passwords[0].value)

kubectl create secret docker-registry "${acr_name}.azurecr.io" \
    --docker-server="https://${acr_name}.azurecr.io" \
    --docker-username="${acr_name}" \
    --docker-password="${acr_pass}" \
    --docker-email="root@${acr_name}"

echo "Password stored in k8s is $(
    kubectl get secret "${acr_name}.azurecr.io" --output=json | \
    jq -r '.data[".dockercfg"]' | \
    base64 -d | \
    jq -r ".[\"https://${acr_name}.azurecr.io\"].password") \
    "
