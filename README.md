# Introduction

This is Developed by Mason Yan and Daniel Ma from Palo Alto Networks. This is a Demo package to install two VM series NGFW and two nginx servers for HA function on AliCloud. Now you can use this but has not been fully tested and supported. Please use or modify it at your own discretion and after sufficient testing.. 

The Terraform deployment below architecture:


# Requirements

To deploy this template, a RAM user with an AccessKey and Secret are required. This user will need access to ECS, VPC, RAM, and FC. For details on creating a RAM user, refer to the AliCloud article [Create a RAM user](https://www.alibabacloud.com/help/doc-detail/28637.htm).


# Deployment Overview

The Terraform script will create the following:

- A Function Compute service and one function:
  - A timer function that runs once per minute to check VM NGFW healthy status and move to standby NGFW when Primary NGFW has problem. And when the Primary NGFW back to normal, swicthing back.
- An AliCloud RAM policy for Function Compute service to perform VPC, ECS changes
- A Virtual Private Cloud (VPC)
- Three security groups, management, trust and untrust
- Three vswitches
- A default route to Primary NGFW
- Two VM series NGFW in separate AZs
- Two nginx servers running in trust vswitches



The default setup is shown below:

![FortiOS Admin Profile](./imgs/Diagram2_AA.png)



# Support

Pls. contact with dma@paloaltonetworks.com or myan@paloaltonetworks.com