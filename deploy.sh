#!/bin/bash

zipping_code(){
	echo "Zipping repository..."
    cd ..
	mkdir python
    rsync -r --exclude '*.git*' ./* ./python
	zip -r code.zip ./python
}

publishing_as_layer(){
	echo "Publishing as a layer..."
	echo "${lambda_layer}"
	local result=$(aws lambda publish-layer-version --layer-name "${INPUT_LAMBDA_LAYER_ARN}" --zip-file fileb://code.zip --region us-east-1)
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm -rf python
	rm code.zip
}

update_function_layers(){
	echo "Using the layer in the functions..."
	aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers "${INPUT_LAMBDA_LAYER_ARN}:${LAYER_VERSION}" --region "us-east-1"
}

deploy_aws_layer(){
	zipping_code
	publishing_as_layer
	update_function_layers
}

deploy_aws_layer
echo "Completed!"