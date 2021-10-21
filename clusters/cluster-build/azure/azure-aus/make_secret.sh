#!/usr/bin/env bash

# Set variables
if [[ -z ${AZ_CLIENT_KEY} ]]; then
  echo "Please provide environment variable AZ_CLIENT_KEY contining the Azure Client Secret"
  exit 1
fi

if [[ -z ${AZ_CLIENT_ID} ]]; then
  echo "Please provide environment variable AZ_CLIENT_ID containg the Azure Client ID"
  exit 1
fi

if [[ -z ${AZ_TEN_ID} ]]; then
  echo "Please provide environment variable AZ_TEN_ID containing the Azure Tenant ID"
  exit 1
fi

if [[ -z ${AZ_SUB_ID} ]]; then
  echo "Please provide environment variable AZ_SUB_ID containing the Azure Subscription ID"
  exit 1
fi

if [[ -z ${SSH_PRIV_FILE} ]]; then
  echo "Please provide environment variable SSH_PRIV_FILE"
  exit 1
fi

if [[ -z ${SSH_PUB_FILE} ]]; then
  echo "Please provide environment variable SSH_PUB_FILE"
  exit 1
fi

if [[ -z ${PULL_SECRET} ]]; then
  echo "Please provide environment variable PULL_SECRET"
  exit 1
fi

if [[ -z ${CLUSTER_NAME} ]]; then
  echo "Please provide environment varaible for CLUSTER_NAME, which is the name of the cluster, this should be the same in the values file."
  exit 1
fi

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTROLLER_NAME=${SEALED_SECRET_CONTROLLER_NAME:-sealed-secrets}

#form the data strucutre containing all the different ids
AZ_ID='{"clientId": "'$AZ_CLIENT_ID'", "clientSecret": "'$AZ_CLIENT_KEY'", "tenantId": "'$AZ_TEN_ID'", "subscriptionId": "'$AZ_SUB_ID'"}'

#read in public ssh key
ssh_pub_key=$(cat ${SSH_PUB_FILE})

#generate the install-config.yaml, we need to copy it to the templates folder for helm to render it...whhy?
cp install-config/install-config.azure.yaml templates/

install_config=$(helm template install-config . -s templates/install-config.azure.yaml --set provider.sshPublickey="$ssh_pub_key" --values values.yaml | sed -e '/---/d' -e '/Source/d')
#remove the install config from templates so helm doesnt try to install it
rm templates/install-config.azure.yaml
ENC_INST_CFG=$(echo -n "$install_config" | kubeseal --raw --name=$CLUSTER_NAME-install-config --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating Secrets"
ENC_AZ_ID=$(echo -n ${AZ_ID} | kubeseal --raw --name=$CLUSTER_NAME-azure-creds --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_PULL_SECRET=$(echo -n ${PULL_SECRET} | kubeseal --raw --name=$CLUSTER_NAME-pull-secret --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PRIV=$(cat ${SSH_PRIV_FILE} | kubeseal --raw --name=$CLUSTER_NAME-ssh-private-key --namespace=$CLUSTER_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)


sed -i '' -e 's#.*azure_creds.*$#    azure_creds: '$ENC_AZ_ID'#g' values.yaml
sed -i '' -e 's#.*pullSecret.*$#    pullSecret: '$ENC_PULL_SECRET'#g' values.yaml
sed -i '' -e 's#.*sshPrivatekey.*$#    sshPrivatekey: '$ENC_SSH_PRIV'#g' values.yaml
sed -i '' -e 's#.*installConfig.*$#    installConfig: '$ENC_INST_CFG'#g' values.yaml

