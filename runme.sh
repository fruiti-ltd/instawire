#!/bin/bash
set -e -o pipefail

THIS_DIR=$(cd "$(dirname '${0}')"; pwd -P)
CONFIG_DIR="${THIS_DIR}/config"
TERRAFORM_DIR="${THIS_DIR}/src/terraform"

PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)
WIREGUARD_PORT=51820

KEY_PAIR_NAME="instawire"

mkdir -p $CONFIG_DIR

generate_id() {
   IP_HASH=$(echo -n $PUBLIC_IP | sha512sum | base64)
   DATE=$(date '+%Y%m%d%H%M%S')
   ID="instawire-${DATE}-${IP_HASH:4:10}"
   echo -n "${ID}" > "${CONFIG_DIR}/id"
}

generate_keypair() {
   mkdir -p $CONFIG_DIR
   ssh-keygen -t rsa  -b 2048 -f "${CONFIG_DIR}/${KEY_PAIR_NAME}" -C instawire -N ""
}

get_region() {
   read -p "Enter region (eu-west-2 | us-east-1 | etc): " REGION
   echo -n "${REGION}" > "${CONFIG_DIR}/region"
}

help() {
   echo -e "$(cat ${THIS_DIR}/README.md)"
}

set_terraform_variables() {
   export TF_VAR_name=$(cat ${CONFIG_DIR}/id)
   export TF_VAR_region=$(cat ${CONFIG_DIR}/region)
   export TF_VAR_allowed_ips="[\"$PUBLIC_IP/32\"]"
   export TF_VAR_public_key=$(cat ${CONFIG_DIR}/${KEY_PAIR_NAME}.pub)
   echo "Name: ${TF_VAR_name}"
   echo "Region: ${TF_VAR_region}"
   echo "Allowed IPs: ${TF_VAR_allowed_ips}"
   echo "Public Key: ${TF_VAR_public_key}"
}

start() {
   terraform_apply
}

stop() {
   terraform_destroy
}

terraform_apply() {
   if [[ ! -f "${CONFIG_DIR}/id" ]]; then
      generate_id
   fi

   if [[ ! -f "${CONFIG_DIR}/region" ]]; then
      get_region
   fi

   if [[ ! -f "${CONFIG_DIR}/${KEY_PAIR_NAME}" ]]; then
      generate_keypair
   fi

   set_terraform_variables

   cd $TERRAFORM_DIR
   terraform init
   terraform apply -auto-approve
   SSH_HOST=$(terraform output -raw vpn_server_ip)

   cd $THIS_DIR
   while true; do
      CONFIG_FILE="./config/aws-${SSH_HOST}.conf"
      if [[ -f $CONFIG_FILE ]]; then
         break
      else 
         echo "Waiting for $CONFIG_FILE"
         sleep 5
         scp -o StrictHostKeyChecking=no -r -i "${CONFIG_DIR}/${KEY_PAIR_NAME}" \
            "ubuntu@${SSH_HOST}:~/configs/*" "config" || true
      fi
   done
}

terraform_destroy() {
   set_terraform_variables
   cd $TERRAFORM_DIR
   terraform destroy -auto-approve
   cd $THIS_DIR
}

terraform_graph() {
   set_terraform_variables
   cd $TERRAFORM_DIR
   terraform graph | dot -Tsvg > $THIS_DIR/docs/terraform_graph.svg
   cd $THIS_DIR
}

test() {
   echo "TEST MODE"
   echo -n "us-east-1" > "$CONFIG_DIR/region"
   terraform_apply
   test_wireguard_config_exists
   terraform_destroy
}

test_wireguard_config_exists() {
   cd $TERRAFORM_DIR
   vpn_server_ip=$(terraform output -raw vpn_server_ip)
   cd $THIS_DIR

   config_file="$CONFIG_DIR/aws-${vpn_server_ip}.conf"

   if [[ -f $config_file ]]; then
      echo -e "\nTEST PASSED: ${config_file} exists\n"
   else
      echo -e "\nTEST FAILED: ${config_file} does not exist\n"
      exit 1
   fi
}

$1; if [[ -z $1 ]]; then help; fi
