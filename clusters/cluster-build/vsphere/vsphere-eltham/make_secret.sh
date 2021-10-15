#!/usr/bin/env bash

# Set variables
if [[ -z ${VSPH_PASS} ]]; then
  echo "Please provide environment variable VSPH_PASS containing the vSphere passowrd"
  exit 1
fi

if [[ -z ${VSPH_USER} ]]; then
  echo "Please provide environment variable VSPH_PASS containing the vsphere user"
  exit 1
fi

if [[ -z ${SSH_PRIV_FILE} ]]; then
  echo "Please provide environment variable SSH_PRIV_FILE"
  exit 1
fi

if [[ -z ${SSH_PUB_FILE} ]]; then
  echo "Please provide environment variable SSH_PUB_FILE, containing the path to matching public ssh key matched to the private key"
  exit 1
fi

if [[ -z ${VSPH_PUB_CA_FILE} ]]; then
  echo "Please provide environment variable VSPH_PUB_CA_FILE, containing the path to matching public certificate for the vcenter server"
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

#read in public ssh key
ssh_pub_key=$(cat ${SSH_PUB_FILE})

#generate the install-config.yaml, we need to copy it to the templates folder for helm to render it...whhy?
cp install-config/install-config.vsphere.yaml templates/

install_config=$(helm template install-config . -s templates/install-config.vsphere.yaml --set provider.username=${VSPH_USER},provider.password=${VSPH_PASS},provider.sshPublickey="$ssh_pub_key" --values values.yaml | sed -e '/---/d' -e '/Source/d')
#remove the install config from templates so helm doesnt try to install it
rm templates/install-config.vsphere.yaml
ENC_INST_CFG=$(echo -n "$install_config" | kubeseal --raw --name=$CLUSTER_NAME-install-config --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating Secrets"
ENC_VSPH_USER=$(echo -n ${VSPH_USER} | kubeseal --raw --name=$CLUSTER_NAME-vsphere-creds --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_VSPH_PASS=$(echo -n ${VSPH_PASS} | kubeseal --raw --name=$CLUSTER_NAME-vsphere-creds --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_PULL_SECRET=$(echo -n ${PULL_SECRET} | kubeseal --raw --name=$CLUSTER_NAME-pull-secret --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PRIV=$(cat ${SSH_PRIV_FILE} | kubeseal --raw --name=$CLUSTER_NAME-ssh-private-key --namespace=$CLUSTER_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PUB=$(cat ${SSH_PUB_FILE} | kubeseal --raw --name=$CLUSTER_NAME-ssh-private-key --namespace=$CLUSTER_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_VSPH_PUB_CA=$(cat ${VSPH_PUB_CA_FILE} | kubeseal --raw --name=$CLUSTER_NAME-vsphere-certs --namespace=$CLUSTER_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

echo "Updating values file with encrypted secrets"
sed -i '' -e 's#.*username.*$#    username: '$ENC_VSPH_USER'#g' values.yaml
sed -i '' -e 's#.*password.*$#    password: '$ENC_VSPH_PASS'#g' values.yaml
sed -i '' -e 's#.*pullSecret.*$#    pullSecret: '$ENC_PULL_SECRET'#g' values.yaml
sed -i '' -e 's#.*sshPrivatekey.*$#    sshPrivatekey: '$ENC_SSH_PRIV'#g' values.yaml
sed -i '' -e 's#.*sshPublickey.*$#    sshPublickey: '$ENC_SSH_PUB'#g' values.yaml
sed -i '' -e 's#.*installConfig.*$#    installConfig: '$ENC_INST_CFG'#g' values.yaml
sed -i '' -e 's#.*cacertificate.*$#    cacertificate: '$ENC_VSPH_PUB_CA'#g' values.yaml