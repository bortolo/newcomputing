# VPC NAT instance Vs NAT gateway test

Deploy a VPC with a public and e private EC2. Test internet connectivity throuth the AWS internet gateway and through NAT gateway Vs NAT instance.

![appview](./images/EBSarchitecture.png)

| Resource | Estimated cost (without VAT) | Link |
|------|---------|---------|
| EC2 t2.micro (public instance) | 0,013 $/h | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| EC2 t2.micro (private instance) | 0,013 $/h | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| EC2 t2.micro (NAT instance) | 0,013 $/h | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| NAT gateway | 0,052 $/h + 0,052 $/GB | [Pricing](https://aws.amazon.com/vpc/pricing/) |


| Automation | Time |
|------|---------|
| Time to deploy | 2 min (with NAT gateway, which is the longest provisioning) |
| Time to destroy | 1 min |

## Useful links

[VPC pricing](https://aws.amazon.com/vpc/pricing/)

[VPC](https://ibm-learning.udemy.com/course/aws-certified-solutions-architect-associate-saa-c02/learn/lecture/13528540#overview)

[Subnets](https://ibm-learning.udemy.com/course/aws-certified-solutions-architect-associate-saa-c02/learn/lecture/13528542#overview)

[IGW and Route tables](https://ibm-learning.udemy.com/course/aws-certified-solutions-architect-associate-saa-c02/learn/lecture/13528544#overview)

[NAT instances](https://ibm-learning.udemy.com/course/aws-certified-solutions-architect-associate-saa-c02/learn/lecture/13528548#overview)

[NAT gateway](https://ibm-learning.udemy.com/course/aws-certified-solutions-architect-associate-saa-c02/learn/lecture/13528550#overview)

### Deploy

Update the `input.tfvars` file with your own inputs (es. `example_input.tfvars`). Choose if you want to deploy the example with a NAT instance or with a NAT gateway (`nat_instance_or_gateway` variable).
Don't forget to generate your [public ssh key](https://www.ssh.com/ssh/keygen/).
***Note:*** we are deploying subnets in two availability zones, so please choose a regione where there are at least two AZs (AZ a & AZ b).

Initialize terraform root module with all the provider plugins and module needed to run this example:
```
terraform init
```
Verify with `terraform plan` command if everything is ok
```
terraform plan -var-file="input.tfvars"
```
Now you can deploy the AWS resources with terraform.

```
terraform apply -var-file="input.tfvars"
```

If you want to print again the outputs after you already run the `terraform apply` command you can just run `terraform output`

Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

### Test

To set up the internet connection of the private instance you have to login in the public instance:
```
ssh ubuntu@<ec2_public_ipPub>
```
Then you have to copy paste your private ssh key (id_rsa) on this instance. This **is not a best practice** procedure, we are following this approach just to easily show the NAT features.
Print on your local terminal your private id_rsa:
```
cd
more .ssh/id_rsa
```
You should get a page like the following
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAQEAlTyPsvVSv9io..
..
..
..
.....HJlYWJvcnRvbG9zc2lAQW5kcmVhcy1NQlAubGFuAQI=
-----END OPENSSH PRIVATE KEY-----
```
Copy paste the full content (from header to footer included) on a new file on the ec2_public instance:
```
nano .ssh/id_rsa
```
Change the permission of the id_rsa file
```
chmod 400 .ssh/id_rsa
```
Now you are ready to login on the ec2_private instance
```
ssh ubuntu@<ec2_private_ipPrivate>
```
From this instance try to ping a website to see if you are connected to the internet
```
ping google.com
```
You can change the `nat_instance_or_gateway` variable to see that with Nat instance or with Nat gatewy we can achieve the same result. You can also change the subnet allocation inside the main.tf file of the ec2 instances to see the effects.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.21 |
| aws | >= 2.68 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.68 |

## Inputs

| Name | Description |
|------|---------|
| awsusername | Aws username |

## Outputs

| Name | Description |
|------|-------------|
| ec2_public_ipPub | The public IP of the public EC2 instance |
| ec2_private_ipPrivate | The private IP of the private EC2 instance |