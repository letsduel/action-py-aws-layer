#!/bin/bash

configure_aws_credentials(){
	aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
    aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
    aws configure set default.region ${AWS_DEFAULT_REGION}
}

zipping_code(){
	echo "Zipping repository..."
    cd ..
	mkdir python
    rsync -r --exclude '*.git*' ./* ./python
	zip -r code.zip ./python
}

publishing_as_layer(){
	echo "Publishing as ${lambda_layer} layer..."

	#local result=$(aws lambda publish-layer-version --layer-name "${lambda_layer}" --zip-file fileb://code.zip --region us-east-1)
	LAYER_ARN="arn:aws:lambda:us-east-1:343449118303:layer:pymongo" #$(jq '.LayerVersion' <<< "$result")
	LAYER_VERSION_ARN="arn:aws:lambda:us-east-1:343449118303:layer:pymongo:6" #$(jq '.LayerVersionArn' <<< "$result")
	rm -rf python
	rm code.zip
}

update_function_layers(){
	echo "Using the layer in the functions... ${lambda_functions} ${lambda_layer}"

	echo "Fetching exisitng layers in function"
	local res=$(aws lambda get-function --function-name "${lambda_functions}")
	local existLayers=$(jq '.Configuration.Layers | map(select(.Arn | contains ("${LAYER_ARN}") | not ) | .Arn ) | join(" ")' <<< "$res")

	if [ $(wc -w <<< $existLayers) -le 4 ]
	then 
		echo "Adding layer to function"
		local resp=$(aws lambda update-function-configuration --function-name "${lambda_functions}" --layers "${LAYER_VERSION_ARN} ${existLayers}" --region "us-east-1")

		if [ $(jq '.LastUpdateStatus' <<< "$resp") == "Successfull"]
		then 
			echo "Successful"
		else
			echo "error: ${resp}"
		fi

	else 
		echo "Too many layers on function ${lambda_functions}"
	fi
}

deploy_aws_layer(){
	#export
	#configure_aws_credentials
	zipping_code
	publishing_as_layer
	update_function_layers
}

deploy_aws_layer
echo "Completed!"