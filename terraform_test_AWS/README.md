# AWS tests

Welcome to the ***AWS test*** section, here you can find several examples of AWS resource deployments. All the folders include at least some ***.tf*** files to deploy AWS resources through terraform commands. Some subfolders may also include ***.yml*** files (ansible deployments), javascript files (we mainly use node.js app for our examples) and ***.io*** files (we use draw.io to draw AWS architectures).
The typical folder structure is the following:
- main.tf
- outputs.tf
- variables.tf
- versions.tf
- input.tfvars
- README.md
- **playbook**
- **node**
- **images**

## Examples

This is the list of the available tests with a short description. Click on one of them if you are interested to examine in depth.

### Single examples

- **[Example - S01](./CloudWatch)**
  - **Status**, DONE (alpha)
  - **Description**, deploy some EC2 instances and monitor them through CloudWatch dashboard.
- **[Example - S02](./SQS)**
  - **Status**, WIP
  - **Description**, WIP
- **[Example - S03](./SNS)**
  - **Status**, WIP
  - **Description**, WIP
- **[Example - S04](./EBS)**
  - **Status**, DONE (alpha)
  - **Description**, create several EBS volumes and test their performances (IOPS, latency and throughput).
- **[Example - S05](./VPC)**
  - **Status**, DONE (alpha)
  - **Description**, deploy a custom VPC and several EC2 instances to test route tables from remote workstation and inside AWS.
- **[Example - S06](./IAM)**
  - **Status**, WIP
  - **Description**, create several users and groups on AWS IAM. Assign users to groups and upload custom policies.
- **[Example - S07](./S3website)**
  - **Status**, WIP
  - **Description**, deploy a react website on S3
- **[Example - S08](./Backup)**
  - **Status**, WIP
  - **Description**, deploy EC2 and EBS, set backup jobs

### Multi Step examples

- **[Example - MS01](./FullApplication)**
  - **Status**, DONE (alpha)
  - **Description**, deploy a node.js app on EC2 and work with RDS, SecretsManager, VPC peering and several others AWS services.

## Getting started
### Install and configure terraform

Have look to this [guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) to set-up your terraform environment.

### Install and configure ansible

Have look to this [guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) to set-up your ansible environment.

### Configure AWS credentials locally

In order to run terraform and/or ansible commands you have to export AWS crediantals in your local environment. Run the following commands from CLI:
```
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxx
```
If you are the administrator/owner of your AWS account you can generate the access key from the AWS web-console. Go to *Users* and select your user (if you did not create your first user please do it and assign him administrative access). Go to the panel *Security Credentials* and click on *Create access key* button.

If you are not the administrator/owner of the AWS account, contact your AWS account administrator to get the access keys.

**TIP,** to avoid to run each time these two commands just create a simple bash script like this one
```
#!/bin/sh
# echo "Setting environment variables for Terraform to use AWS"
export AWS_IAM_USER=<your-user-name>
export AWS_ACCESS_KEY_ID=<your-access-key-id>
export AWS_SECRET_ACCESS_KEY=<your-secret-access-key-id>
```
Save it as activateAWS.sh (don't store it in a shared repository) and make it executable:
```
chmod +x activateAWS.sh
```
Execute it everytime you open a new CLI session:
```
. ./activateAWS.sh
```
