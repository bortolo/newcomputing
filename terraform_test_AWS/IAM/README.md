# SET-UP IAM

This script deploys users and groups.
It is possible to set-up different policies for different groups.

**IMPORTANT:** you must be an AWS administrator to run this test.

## Add an user

Define a new user in `main.tf` in the section `IAM user`. `XX` is the number of the new user (remember, must be unique, you can't have two modules with the same name).
```
module "iam_userXX" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-user"
  name = "user-name"                    // your username
  force_destroy = true
  create_iam_user_login_profile = true  // generate login password
  pgp_key = "your-pgp-key"               //public key to generate login password
  create_iam_access_key         = true  // generate API access key (useful for terraform provisioning)
}
```
In the section `IAM groups` add the user in the correct group.
```
module "iam_group_complete_administrators" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name = "administrators"
  group_users = [
    module.iam_user1.this_iam_user_name,
    module.iam_user3.this_iam_user_name,
    module.iam_userXX.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
```
Add the correct output in `output.tf`. Copy a full section from a previous `IAM User y` and append it at the end of the file. Update the user number on all the functions of this new section.

To generate the `pgp_key` on your local machine do the following steps

#### Install gnupg
macOS
```
brew install gnupg
```
Ubuntu
```
sudo apt install gnupg
```
#### Generate an encryption key
```
gpg  --generate-key
```
#### Export the public key
With the following command you will get the `"your-pgp-key"`
```
gpg --export <public-key-id> | base64
```
The `<public-key-id>` parameter can be found by listing all keys.
```
gpg --list-keys
```

### Retrieve new user credentials
Run `terraform apply` to deploy the new user.
At the end you will get important outputs on your CLI.
To get the login password you have to decrypt the `userXX_login_profile_encrypted_password` output.
```
terraform output userXX_login_profile_encrypted_password | base64 -D | gpg --decrypt
```
Use you username and this password to access the AWS console.
Do the same with `userXX_access_key_encrypted_secret` to get the API secret.

Sometime GPG is confused where to read input from. Simply configuring it to look for input from tty (the terminal connected to standard input):
```
export GPG_TTY=$(tty)
```

## Add a group
Define a new group in `main.tf` in the section `IAM groups`.
Remember that module names must be unique. Define the users to be included in this group in `group_users` and the policy to attach to this group in `custom_group_policy_arns`. Browse among the ready-to-use polices in AWS and select the arn value.

```
module "iam_group_complete_XXXXXXXX" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name = "EC2users"
  group_users = [
    module.iam_user2.this_iam_user_name,
    module.iam_user3.this_iam_user_name,
    module.iam_user4.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]
}
```

## Custom policies
Deny action on specific Regions - https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-requested-region.html

## USEFUL WEB resources

Getting started with policy simulator
https://www.youtube.com/watch?v=1IIhVcXhvcE

Setting up an AWS organization from scratch with Terraform
https://tbekas.dev/posts/setting-up-an-aws-organization-from-scratch-with-terraform
