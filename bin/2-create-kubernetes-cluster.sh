
echo "name              ${K8SCLUSTERNAME}"
echo "resource-group    ${RGNAME}"
echo "location          ${K8SLOCATION}"
echo "dns-prefix        ${DNSPREFIX}"
echo "ssh-key-value     ${sshkey}"
echo "service-principal ${AZURE_PACKER_APPID}"
echo "client-secret     ${AZURE_PACKER_PASSWORD}"

az acs create \
   --name="${K8SCLUSTERNAME}" \
   --resource-group="${RGNAME}" \
   --location="${K8SLOCATION}" \
   --orchestrator-type=kubernetes \
   --dns-prefix="${DNSPREFIX}" \
   --ssh-key-value="${sshkey}" \
   --service-principal="${AZURE_PACKER_APPID}" \
   --client-secret="${AZURE_PACKER_PASSWORD}" \
   --master-count=1 \
   --agent-count=2 \
   --agent-vm-size="Standard_DS1_v2" \
   --admin-username="chgeuer" \
   --admin-password="${AZURE_LINUX_PASSWORD}"
