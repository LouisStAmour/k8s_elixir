
# curl --silent --basic --user "${acr_name}:${acr_pass}" -H "Content-Type: application/json" --url "https://${acr_name}.azurecr.io/v2/_catalog" | jq '.repositories'

# export acr_name=chgeuerregistry2
# export acr_pass=$(az acr credential show --name $acr_name | jq -r .passwords[0].value)


function docker_tag_exists {
    EXISTS=$(curl --silent \
	    --basic \
	    --user "${acr_name}:${acr_pass}" \
	    -H "Content-Type: application/json" \
        --url "https://${acr_name}.azurecr.io/v2/$1/tags/list" \
        | jq ".tags" \
        | jq "contains([\"$2\"])")

    test $EXISTS = true
}


image="chgeuer/elixir"
tag="1.4.4"

if docker_tag_exists "${image}" "${tag}"; then
	echo exist
else 
	echo not exists
fi
