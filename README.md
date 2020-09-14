# Introduction

This is Developed by Mason Yan and Daniel Ma from Palo Alto Networks. This is a Demo package to install two VM series NGFW and two nginx servers for HA function on AliCloud. Now you can use this but has not been fully tested and supported. Please use or modify it at your own discretion and after sufficient testing.. 


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

The Terraform deployment below architecture:
![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/Architecture_in.png)
![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/Architecture_out.png)
![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/Monitoring.png)
![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/Switching_standby_in.png)
![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/Switching_standby_out.png)

# Deployment
1. Update the VM-series_vars.tf with correct information, like the ASAK, image name, region etc. Or you can provide those info with "terraform apply -var access_key="<access_key>" -var secret_key="<secret_key>"
2. terraform init
3. terraform apply
4. Demo infra will be deployed, and you can expect below error:
    Error: [ERROR] terraform-provider-alicloud/alicloud/resource_alicloud_fc_function.go:173: Resource alicloud_fc_function CreateFunction Failed!!! [SDK fc-go-sdk ERROR]:
    [ERROR] terraform-provider-alicloud/alicloud/resource_alicloud_fc_function.go:166:
    {
      "HttpStatus": 400,
      "RequestId": "87b2f37d-1286-4ff3-99b6-ea521deb87ec",
      "ErrorCode": "InvalidArgument",
      "ErrorMessage": "Environment variable value doesn't match expected format (allowed: ^[[:print:]]+$, actual: '')"
    }

  on main.tf line 353, in resource "alicloud_fc_function" "active-standby":
 353: resource "alicloud_fc_function" "active-standby" {

5. This error is expected, because during the deployment, it will run a script to get the Primary NGFW access_key with pre-defined username and password of the NGFW. It can only success after the primary NGFW up and running. So you need to wait for about 5 mins to run " terraform plan | grep API_KEY " and check if the access_key has been generated. Check for below section:
          + "API_KEY"            = ""
Until the "API_KEY" hhas a value back, like below:
          + "API_KEY"            = "LUFRPT1WdGx**************************"

6. Now you can run "terraform apply" again to update this key to the FC environment table.

7. When finished, it will shows up necessary info for you to continue:

    Outputs:

    SLB-IP-Address = 10.0.6.82

    VM-Series-MGMTIP = 47.242.129.211

    VM-Series-MGMTIP-2 = 47.242.92.207

    VM-Series-UNTRUSTIP = 8.210.183.24 *** Please manually attach this IP to Untrust ENI. ***


8. Access the Primary and Standby NGFW with the IP address output "VM-Series-MGMTIP", "VM-Series-MGMTIP-2" with username and password for your image.
Update the NAT policy DNAT address to the output of "SLB-IP-Address = 10.0.6.82" for both NGFW.

![image](https://github.com/danielma911/Alicloud_VM_HA/blob/master/imgs/DNAT.png)

9. Licensing both the Primary and Standby NGFW

10. Important: attach the Untrust EIP "VM-Series-UNTRUSTIP" to the Primary NGFW untrust ENI. 

11. Now you are ready to go.

# Uninstall

1. Unbind the EIP "VM-Series-UNTRUSTIP" from the NGFW untrust interface[important]

2. Run "terraform destroy"

# Support

Pls. contact with dma@paloaltonetworks.com or myan@paloaltonetworks.com
