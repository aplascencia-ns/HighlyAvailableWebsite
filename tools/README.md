# Operation Tool


## Pre-requisites

* You must have [Terraform](https://www.terraform.io/) installed on your computer. 
* You must have an [Amazon Web Services (AWS) account](http://aws.amazon.com/).

Please note that this code was written for Terraform 0.12.x.

## Quick start

Configure your [AWS access 
keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) as 
environment variables:

```
export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

Exec the code inside this folder /tools/:

```
sh ap_ops [action] [process_name] [aws_account_name]

example: 
sh ap_ops get sshconfig nearsoft
```

After executed you need to put your privite key name like [private_instance] and you will have a new ssh config file in the default path

```
~/.ssh/config
```

and a new file named [config_backup] with your previous configs
