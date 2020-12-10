# Cloudwath Dashboards

Deploy three EC2 instances and monitor them through a Cloudwatch dashboard. Run some stress test to see CPU usage and CPUcredit usage.

![appview](./images/CloudWatch.png)

| Resource | Estimated cost (without VAT) | Link |
|------|---------|---------|
| EC2 | 0,013 $/h x # of instances | [Pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| Cloudwatch | you can easely remain in the free tier | [Pricing](https://aws.amazon.com/cloudwatch/pricing/) |

| Automation | Time |
|------|---------|
| Time to deploy (Terraform) | 2 min |
| Time to deploy (Ansible) | 30 sec |
| Time to destroy | 1 min |

## Useful link

[Customize CloudWatch widget](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html)

[stress e stress-ng suite](https://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/)

## Usage

Update the `input.tfvars` file with your own inputs (es. `example_input.tfvars`).

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

Note that this example may create resources which can cost money. When you don't need these resources just run:
```
terraform destroy -var-file="input.tfvars"
```