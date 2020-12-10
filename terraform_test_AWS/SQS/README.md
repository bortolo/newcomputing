# Deploy SQS

## Useful links

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