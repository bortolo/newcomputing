# AWS tests

Here you can find many different deployments with terraform and ansible.
We are extensively using these terraform [modules](../modules_AWS), so please download also this folder to run with success the following examples.

Have a look to [this](https://learn.hashicorp.com/tutorials/terraform/aws-build) brief guide about terraform, if you are a beginner using terraform on AWS.

This is the list of the available tests with a short description. Click on one of them if you are interested to examine in depth.

- **[Start from VPC and EC2](./VPC)**
  - **Status**, DONE (alpha)
  - **Description**, deploy a custom VPC and several EC2 instances to test route tables from remote workstation and inside AWS.
- **[Try an application deployment](./FullApplication)**
  - **Status**, DONE (alpha)
  - **Description**, deploy a node.js app on EC2 and work with RDS, SecretsManager, VPC peering.
- **[Test EBS volume performances](./EBS)**
  - **Status**, DONE (alpha)
  - **Description**, create several EBS volumes and test their performances (IOPS, latency and throughput).
- **[IAM](./IAM)**
  - **Status**, WIP
  - **Description**, create several users and groups. Assign users to groups and upload custom policies.
- **[Deploy a react website on S3](./S3website)**
  - **Status**, WIP
  - **Description**, WIP
- **[Deploy EC2 and EBS, set backup jobs](./Backup)**
  - **Status**, WIP
  - **Description**, WIP

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
