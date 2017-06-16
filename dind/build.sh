export uuid=$(uuidgen)
envsubst < job-parametrized.yaml | kubectl create -f -

sleep 5
kubectl logs --follow=true --container='build-job' $(kubectl get pods --show-all --selector=job-name=build-job-${uuid} --output=jsonpath={.items..metadata.name}) 
