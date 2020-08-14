#!/bin/bash

configure_aws_credentials(){
	aws configure set aws_access_key_id "${INPUT_AWS_ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${INPUT_AWS_SECRET_ACCESS_KEY}"
    aws configure set default.region "${INPUT_LAMBDA_REGION}"
}

zipping_code(){
	echo "Zipping repository..."
    cd ..
	mkdir python
    rsync -r --exclude '*.git*' ./* ./python
	zip -r code.zip ./python
}

publish_as_layer(){
	echo "Publishing as a layer..."
	local result=$(aws lambda publish-layer-version --layer-name "${INPUT_LAMBDA_LAYER_ARN}" --zip-file fileb://code.zip)
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm -rf python
	rm code.zip
}

publish_function_code(){
	echo "Deploying the code itself..."
	zip -r code.zip . -x \*.git\*
	aws lambda update-function-code --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --zip-file fileb://code.zip
}

update_function_layers(){
	echo "Using the layer in the functions..."
	aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers "${INPUT_LAMBDA_LAYER_ARN}:${LAYER_VERSION}"
}

deploy_lambda_function(){
    #configure_aws_credentials
	zipping_code
	publish_as_layer
	#publish_function_code
	update_function_layers
}

deploy_lambda_function
echo "Each step completed, check the logs if any error occured."