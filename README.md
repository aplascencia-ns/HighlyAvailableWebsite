# HighlyAvailableWebsite

## Quick start

**Note**: These examples deploy resources into your AWS account. Although all the resources should fall under the
[AWS Free Tier](https://aws.amazon.com/free/), it is not our responsibility if you are charged money for this.

1. Install [Terraform](https://www.terraform.io/).
1. Set your AWS credentials as the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
1. `cd` into `/global/s3/` folder and follow the instructions.
1. Then you could deploy demo or staging. Inside folder you could see the instructions.
1. After it's done deploying, the example will output URLs or IPs you can try out.
1. To clean up and delete all resources after you're done, run `terraform destroy`.
