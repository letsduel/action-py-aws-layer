#!/bin/bash

configure_aws_credentials(){
	aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
    aws configure set default.region "${AWS_DEFAULT_REGION}"
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

	local result=$(aws lambda publish-layer-version --layer-name "${lambda_layer}" --zip-file fileb://code.zip --region us-east-1)
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm -rf python
	rm code.zip
}

update_function_layers(){
	echo "Using the layer in the functions..."
	aws lambda update-function-configuration --function-name "${lambda_functions}" --layers "${lambda_layer}:${LAYER_VERSION}" --region "us-east-1"
}

deploy_aws_layer(){
	configure_aws_credentials
	zipping_code
	publishing_as_layer
	update_function_layers
}

deploy_aws_layer
echo "Completed!"