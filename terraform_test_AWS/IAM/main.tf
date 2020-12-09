provider "aws" {
  region = "eu-west-1"
}



############
# IAM users
############

module "iam_user1" {
  source                        = "../../modules_AWS/terraform-aws-iam-master/modules/iam-user"
  name                          = "Andrea"
  force_destroy                 = true
  create_iam_user_login_profile = true
  pgp_key                       = "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"
  create_iam_access_key         = true
}

module "iam_user2" {
  source                        = "../../modules_AWS/terraform-aws-iam-master/modules/iam-user"
  name                          = "Sara"
  force_destroy                 = true
  create_iam_user_login_profile = true
  pgp_key                       = "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"
  create_iam_access_key         = true
}

module "iam_user3" {
  source                        = "../../modules_AWS/terraform-aws-iam-master/modules/iam-user"
  name                          = "Chiara"
  force_destroy                 = true
  create_iam_user_login_profile = true
  pgp_key                       = "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"
  create_iam_access_key         = true
}

module "iam_user4" {
  source                        = "../../modules_AWS/terraform-aws-iam-master/modules/iam-user"
  name                          = "Marco"
  force_destroy                 = true
  create_iam_user_login_profile = true
  pgp_key                       = "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"
  create_iam_access_key         = true
}

#############################################################################################
# IAM groups
#############################################################################################

module "iam_group_complete_administrators" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name   = "administrators"
  group_users = [
    module.iam_user1.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

module "iam_group_complete_EC2_restricted_users" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name   = "EC2_restricted_users"
  group_users = [
    module.iam_user2.this_iam_user_name,
    module.iam_user3.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    aws_iam_policy.EC2_restricted.arn,
  ]
}

module "iam_group_complete_SelfMgmt" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name   = "IAMSelf"
  group_users = [
    module.iam_user4.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
    "arn:aws:iam::aws:policy/IAMSelfManageServiceSpecificCredentials",
    "arn:aws:iam::aws:policy/IAMUserChangePassword",
    aws_iam_policy.self_manage_vmfa.arn,
  ]
}

module "iam_group_complete_BillingViewer" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name   = "BillingViewer"
  group_users = [
    module.iam_user2.this_iam_user_name,
    module.iam_user3.this_iam_user_name,
    module.iam_user4.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
  ]
}

/*
module "iam_group_complete_BillingManager" {
  source = "../../modules_AWS/terraform-aws-iam-master/modules/iam-group-with-policies"
  name = "BillingManager"
  group_users = [
    module.iam_user1.this_iam_user_name,
  ]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/job-function/Billing",
  ]
}
*/
#############################################################################################
# IAM Custom policies
#############################################################################################

resource "aws_iam_policy" "self_manage_vmfa" {
  name   = "SelfManageVMFA"
  policy = file("./custom_policies/self_manage_vmfa.json")
}

resource "aws_iam_policy" "EC2_restricted" {
  name   = "EC2_restricted"
  policy = file("./custom_policies/EC2_restricted.json")
}
