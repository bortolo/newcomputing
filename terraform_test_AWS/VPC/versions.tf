################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure. The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There are 5 type of terraform block in this .tf file:
#
# - terraform; is used to configure some behaviors of Terraform itself
#
# - required_providers: enables one provider (name and version)
#
################################################################################

terraform {
  required_version = ">= 0.12.21"

  required_providers {
    aws = ">= 2.68"
  }
}
