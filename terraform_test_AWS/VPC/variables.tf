################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure. The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There is just 1 type of terraform block in this .tf file:
#
# - variable; the label after the variable keyword is a name for the variable,
#             which must be unique among all variables in the same module.
#             This name is used to assign a value to the variable from outside
#             and to reference the variable's value from within the module.
#
################################################################################

variable "awsusername" {
  description = "(Required) Aws username"
  type        = string
}
