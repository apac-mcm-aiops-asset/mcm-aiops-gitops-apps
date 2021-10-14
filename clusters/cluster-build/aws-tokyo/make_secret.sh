#!/usr/bin/env bash

# Set variables
if [[ -z ${AWS_KEY} ]]; then
  echo "Please provide environment variable AWS_KEY"
  exit 1
fi

if [[ -z ${AWS_ID} ]]; then
  echo "Please provide environment variable AWS_ID"
  exit 1
fi

if [[ -z ${SSH_PRIV_FILE} ]]; then
  echo "Please provide environment variable SSH_PRIV_FILE"
  exit 1
fi

if [[ -z ${PULL_SECRET} ]]; then
  echo "Please provide environment variable PULL_SECRET"
  exit 1
fi

if [[ -z ${DEPLOYMENT_NAME} ]]; then
  echo "Please provide environment varaible for DEPLOYMENT_NAME, which is the name of the cluster, this should be the same in the values file."
  exit 1
fi

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTROLLER_NAME=${SEALED_SECRET_CONTROLLER_NAME:-sealed-secrets}


# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating Secrets"
ENC_AWS_ID=$(echo -n ${AWS_ID} | kubeseal --raw --name=$DEPLOYMENT_NAME-aws-creds --namespace=$DEPLOYMENT_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_AWS_KEY=$(echo -n ${AWS_KEY} | kubeseal --raw --name=$DEPLOYMENT_NAME-aws-creds --namespace=$DEPLOYMENT_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME  --from-file=/dev/stdin)
ENC_PULL_SECRET=$(echo -n ${PULL_SECRET} | kubeseal --raw --name=$DEPLOYMENT_NAME-pull-secret --namespace=$DEPLOYMENT_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PRIV=$(cat ${SSH_PRIV_FILE} | kubeseal --raw --name=$DEPLOYMENT_NAME-ssh-private-key --namespace=$DEPLOYMENT_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)


sed -i '' -e 's#.*aws_access_key_id.*$#    aws_access_key_id: '$ENC_AWS_ID'#g' values.yaml
sed -i '' -e 's#.*aws_secret_access_key.*$#    aws_secret_access_key: '$ENC_AWS_KEY'#g' values.yaml
sed -i '' -e 's#.*pullSecret.*$#    pullSecret: '$ENC_PULL_SECRET'#g' values.yaml
sed -i '' -e 's#.*sshPrivatekey.*$#    sshPrivatekey: '$ENC_SSH_PRIV'#g' values.yaml
