#!/bin/bash

# Input parameters
account_name="$1"
instance_name="bastion"
region="us-east-1"
environment="develop"
key_name="${account_name}-${instance_name}-${region}-${environment}-rsa"


################################################
# Validate if exists entered parameters
################################################
if test -z "$account_name"; then
  echo "Parameter account name (AWS) is empty"
  echo ""
  echo "Enter your account name (AWS): "
  read account_name
fi

# Init variables
file_config_account="./ssh_config/input/config_$account_name"
file_config_original="./ssh_config/input/config_current"
file_config_output="./ssh_config/output/config"
file_config_local="${HOME}/.ssh/config"
file_config_backup="${HOME}/.ssh/config_backup"

################################################
# Validate if exists file and clean it
################################################
if [[ -e ${file_config_account}  ]]; then  
  > ${file_config_account}
else
  touch ${file_config_account}
fi

if [[ -e ${file_config_original}  ]]; then  
  rm ${file_config_original}
fi

if [[ -e ${file_config_output}  ]]; then  
  rm ${file_config_output}
fi

# Backup
cat ${file_config_local} > ${file_config_backup}

# Copy of the current config file
cat ${file_config_local} > ${file_config_original}

########################
# Getting info from AWS
########################
# Bastion info
aws ec2 describe-instances \
--filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=*_bastion" \
--query 'Reservations[*].Instances[*].{imageId:ImageId,publicIp:PublicIpAddress,privateIp:PrivateIpAddress}' \
--output json > ./ssh_config/input/aws_bastion.json

# Private instances info
aws ec2 describe-instances \
--filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=*_private" \
--query 'Reservations[*].Instances[*].{imageId:ImageId,publicIp:PublicIpAddress,privateIp:PrivateIpAddress}' \
--output json > ./ssh_config/input/aws_privates.json

# Set variables like json
bastion=$(cat ./ssh_config/input/aws_bastion.json)
privates=$(cat ./ssh_config/input/aws_privates.json)

# # Getting info private key
# echo "Enter your private key in order to use this AWS account"
# read key_name

# Validate if the files have info if not it will exit
if test -z "$bastion" || test -z "$privates"; then
  echo "Bastion or Private file is empty"
  echo "We cannot process it. Bye"
  exit 1
elif [ "$bastion" == "[]" ] || [ "$privates" == "[]" ]; then
  echo "Bastion or Private file is empty"
  echo "We cannot process it. Bye"
  exit 1
fi

# Init loop in order to create the account filen
for row in $(echo "${bastion}" | jq -r '.[][] | @base64'); do
    _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
    }

    public_ip=$(_jq '.publicIp')
    private_bastion_ip=$(_jq '.privateIp')
    bastion_host=${private_bastion_ip#*.*.}

    for row in $(echo "${privates}" | jq -r '.[][] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }

        # Set variables
        private_ip=$(_jq '.privateIp')
        host=${private_ip#*.*.*.}
        
# Creating Account config
cat >> ${file_config_account} <<EOF
# Generate automatically
Host ${account_name}_private_${bastion_host}_${host}
   HostName $private_ip
   User ubuntu
   ForwardAgent yes
   IdentityFile ${HOME}/.ssh/${key_name}
   ProxyCommand ssh ubuntu@${public_ip} -W %h:%p

EOF
    
    done # end for ${privates}

# Creating Bastion config
cat >> ${file_config_account} <<EOF
# Generate automatically
Host ${account_name}_bastion_${bastion_host}
   HostName $public_ip
   User ubuntu
   ForwardAgent yes
   IdentityFile ${HOME}/.ssh/${key_name}

EOF

done # end for ${bastion}

# Creating output file
# cat ${file_config_account} > ${file_config_output}
