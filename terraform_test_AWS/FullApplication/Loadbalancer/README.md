# Deploy Network Load Balancer

Deploy a EC2 with a node.js app and a mySQL RDS instance. Store the db secret in AWS SecretsManager.

![appview](./images/Loadbalancerarchitecture.png)


| Resource | Estimated cost (without VAT) | Link |
|------|---------|---------|
| NLB | 0.027 $/h + 0.006 $/h per NLCU-hour | [Pricing](https://aws.amazon.com/elasticloadbalancing/pricing/?nc=sn&loc=3) |
| EC2 | 0,013 $/h x # of instances | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| RDS | 0,02 $/h (it can increase if you upload a lot of data, see RDS Storage usage type)| [Pricing](https://aws.amazon.com/rds/mysql/pricing/?pg=pr&loc=2) |
| SecretsManager | <0,4$/month per secret - see pricing | [Pricing](https://aws.amazon.com/secrets-manager/pricing/) |
| Route53 | if deleted within 12h no charges are applied | [Pricing](https://aws.amazon.com/route53/pricing/) |
| Elastic IP | 0 $/h (it costs only if it is not assigned to EC2: 0,05$/h)| [Pricing](https://aws.amazon.com/premiumsupport/knowledge-center/elastic-ip-charges/) |

| Automation | Time |
|------|---------|
| terraform apply | 8 min |
| ansible-playbook | 30 sec |
| terraform destroy | 5 min |

## Useful links

## Usage

### Set db Credentials

Set user, password, AWS SecretsManager name and db DNS name in `set_db_credentials.sh` script and than run it
```
. ./set_db_credentials.sh
```
**Important:** If you already used the same AWS SecretsManager name remember that each AWS secret needs at least 7 days to complete the deletion of the secret. Until the end of this period you cannot use the same secret name.

Set also `config.service` with the same DNS name and with the regione name that you are going to use.

Generete your [public ssh key](https://www.ssh.com/ssh/keygen/) and update `main.tf` file with your `id_rsa.pub` in the field `public_key` of the `aws_key_pair` resource.

Now you can deploy the terraform infrastructure.

### Deploy EC2, RDS and AWS SecretsManager

To run this example you need to execute:

```
$ terraform init
$ terraform plan
$ terraform apply
```
Run terraform apply one more time if something goes wrong.

Note that this example may create resources which can cost money (AWS Elastic IP, for example). Run `terraform destroy` when you don't need these resources.

### Deploy node.js app

Before this step you have to deploy the terraform script.

If you already updated the `config.service` just run the following command from the `playbooks` folder.
```
ansible-playbook -i ./ec2.py ./configure_nodejs.yml -l tag_Name_fe_server
```

On your preferred browser, go to `<elastic_public_ip/view`, you should see a screen like this (with zero rows because the db is still empty)

![appview](./images/appview.png)

### Tests

Run the script `callip.sh`

```
. ./callip.sh
```
This script is doing a while loop calling the `/ip` route of tha node.js app. This route returns the private ip address, the percentage of the not used memory and the percentage the not used cpu of the server hit by the call.

Now try to increase the number of servers changing the `main.tf` in the ec2 module:
```
instance_count = 5
```
Run `terraform apply`. Now you have two more EC2 images but they are not still configured with the nodejs app.
Run again the `ansible-playbook` command that you used before.

Wait for a while and have a look to the terminal window where the script `callip.sh` is running. New private ip addresses will show up soon.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.21 |
| aws | >= 2.68 |
| ansible | >= 2.9.1 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.68 |

## Inputs

| Name | Description |
|------|---------|
| awsusername | Aws username to tag resources with owner |
| db_username | username for the MySQL db |
| db_password | password for the MySQL db |
| db_private_dns | domain called by the node.js app to call the mysql db |
| db_secret_name | name of the secret to store in AWS SecretsManager |

## Outputs

| Name | Description |
|------|---------|
| ec2_public_ips | vector of public ip of EC2 instances |
| ec2_private_ips | vector of public ip of EC2 instances |
| elastic_public_ip | The public ip of the loadbalancer |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
