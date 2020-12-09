# Full application example

In this example we are going to deploy step-by-step a multi-tier application on AWS infrastructure.
The final layout that you are going to build at the end of this tutorial is depicted by the following picture.

![appview](./AMI/images/AMIarchitecture.png)

Here below you can find an index of all the examples related to this tutorial. In each example we are going to focus on a particular component of the final architectural layout. Each step is an auto-consistent that you can run and play with it to gain more confidence with the modules of the full example.

- **STEP1-[RDS](./RDS):** deploy an RDS mysql instance and access it through a local node.js app.
- **STEP2-[RDS + EC2](./EC2andRDS):** deploy an RDS instance and an EC2 instance. Configure EC2 instance with ansible.
- **STEP3-[SecretsManager and IAM role](./SecretManager):** learn how to manage database secrets dynamically and assign role to AWS services.
- **STEP4-[Use a custom VPC](./CustomVPC):** deploy you infrastructure in a custom VPC.
- **STEP5-[Deploy network loadbalancer](./Loadbalancer):** deploy a NLB and try to scale-out manually.
- **STEP6-[Use AMI to promote app into production](./AMI):** deploy a dev environment and build AMI to promote the app into a production environment
