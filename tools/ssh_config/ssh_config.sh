#!/bin/bash

# Init variables
account_name="$1"
file_config_account="./config_$account_name"
file_config_current="./config_current"
file_config_output="./config"
file_config_local="${HOME}/.ssh/config"
file_config_backup="${HOME}/.ssh/config_backup"


################################################
# Validate if exists file and clean it
################################################
if [[ -e ${file_config_account}  ]]; then  
  rm ${file_config_account}
fi

if [[ -e ${file_config_current}  ]]; then  
  rm ${file_config_current}
fi

if [[ -e ${file_config_output}  ]]; then  
  rm ${file_config_output}
fi

# Backup
cat ${file_config_local} > ${file_config_backup}

# Copy of the current config file
cat ${file_config_local} > ${file_config_current}

########################
# Getting info from AWS
########################
# Bastion info
aws ec2 describe-instances \
--filters "Name=owner-id,Values=738397695583" "Name=instance-state-name,Values=running" "Name=tag-value,Values=*_bastion" \
--query 'Reservations[*].Instances[*].{imageId:ImageId,publicIp:PublicIpAddress,privateIp:PrivateIpAddress}' \
--output json > ./aws_bastion.json

# Private instances info
aws ec2 describe-instances \
--filters "Name=owner-id,Values=738397695583" "Name=instance-state-name,Values=running" "Name=tag-value,Values=*_private" \
--query 'Reservations[*].Instances[*].{imageId:ImageId,publicIp:PublicIpAddress,privateIp:PrivateIpAddress}' \
--output json > ./aws_privates.json


# Set variables like json
bastion=$(cat ./aws_bastion.json)
privates=$(cat ./aws_privates.json)


# Init loop in order to create the account file
for row in $(echo "${bastion}" | jq -r '.[][] | @base64'); do
    _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
    }

    public_ip=$(_jq '.publicIp')

    for row in $(echo "${privates}" | jq -r '.[][] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }

        # Set variables
        private_ip=$(_jq '.privateIp')
        host=${private_ip#*.*.*.}
        
# Creating Account config
cat >> ${file_config_account} <<EOF
Host ${account_name}_${public_ip}_${host}
   HostName $private_ip
   User ubuntu
   ForwardAgent yes
   IdentityFile ${HOME}/.ssh/private_instance
   ProxyCommand ssh ubuntu@${public_ip} -W %h:%p

EOF
    
    done # end for ${privates}

done # end for ${bastion}

# cat ${file_config_account}
