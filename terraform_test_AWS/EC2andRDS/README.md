# Custom VPC and peering connections

Deploy a EC2 with a node.js app and a mySQL RDS instance. Store the db secret in AWS SecretsManager.

![appview](./images/CustomVPCarchitecture.png)


| Resource | Estimated cost (without VAT) | Link |
|------|---------|---------|
| EC2 | 0,013 $/h x # of instances | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| RDS | 0,02 $/h x # of instances (it can increase if you upload a lot of data, see RDS Storage usage type)| [Pricing](https://aws.amazon.com/rds/mysql/pricing/?pg=pr&loc=2) |
| SecretsManager | <0,4$/month per secret - see pricing | [Pricing](https://aws.amazon.com/secrets-manager/pricing/) |
| Route53 | if deleted within 12h no charges are applied | [Pricing](https://aws.amazon.com/route53/pricing/) |

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

Set also `config.service` with the same DNS name and with the region name that you are going to use.

Generete your [public ssh key](https://www.ssh.com/ssh/keygen/) and update `main.tf` file with your `id_rsa.pub` in the field `public_key` of the `aws_key_pair` resource.

Now you can deploy the terraform infrastructure.

### Deploy EC2, RDS and AWS SecretsManager

To run this example you need to hide the file `resources.tf` and `outputs.tf` first (rename them as resources.tf.hide and outputs.tf.hide). Then execute:

```
$ terraform init
$ terraform plan
$ terraform apply
```
You have now deployed your custom VPC. Rename againg the `resources.tf` and `outputs.tf` file to the original name and then run again `terraform applly`

Run terraform apply one more time if something goes wrong.

Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

### Deploy node.js app

Before this step you have to deploy the terraform script.

If you already updated the `config.service` just run the following command from the `playbooks` folder (please check if ec2.py is already executable or note, if note run `chmod +x ec2.py`).
```
ansible-playbook -i ./ec2.py ./configure_nodejs.yml -l tag_Name_server_1
```

On your preferred browser, go to `<ec2_1_public_ip>:8080/view`, you should see a screen like this (with zero rows because the db is still empty)

![appview](./images/appview.png)

### Tests

You have now deployed the same configuration showed in the picture. With this configuration you can access all the DBs deployed from EC1 instance. To check this change the `config.service` file. If you want to work with DB2 you have to set `TF_VAR_db_dns=2`, and if you wanto to work with DB3 you have to set `TF_VAR_db_dns=3`.

You can also use EC3 to run the app and work with the DBs. To do this you have to change the `resource.tf` file and assign the `aws_route53_zone` resource to the default VPC (change the comment between row 7 and 8).

Now run `terraform apply` and then release the app on EC3 with ansible:
```
ansible-playbook -i ./ec2.py ./configure_nodejs.yml -l tag_Name_server_3
```
On your preferred browser, go to `<ec2_3_public_ip>:8080/view`, you should see a screen with the same records that you already added in your dbs.

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
| ec2_1_public_ip | public ip of EC1 |
| ec2_1_private_ip | private ip of EC1 |
| ec2_2_public_ip | public ip of EC2 |
| ec2_2_private_ip | private ip of EC2 |
| ec2_3_public_ip | public ip of EC3 |
| ec2_3_private_ip | private ip of EC3 |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
