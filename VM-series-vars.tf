variable "access_key" {
    default = ""
}

variable "secret_key" {
    default = ""
}
variable username {
    default = "admin"
}
variable password {
    default = "Paloalto123"
}

variable "vm-series_instance_type" {
    default = "ecs.sn2ne.xlarge"     # available in HK 
    #default = "ecs.g5.xlarge"       # available in Singapore
    #default = "ecs.sn2.large"     # available in Mainland
}

variable "webserver_instance_type" {
    #default = "ecs.t5-c1m1.large"   // Singapore
    default = "ecs.t6-c2m1.large"  // HongKong
}


variable "image-pri-name" {
    default = "Active-standby-NGFW-9.0-PRI"
}

variable "image-bak-name" {
    default = "Active-standby-NGFW-9.0-BAK"
}
variable "image-pri-id" {
    #default = "m-t4nf2uxmm5gr43xm7kjp"  // Singapore
    default = "m-j6c6n3rzzzc0wn6m2ldq"  // HongKong
}

variable "image-bak-id" {
    #default = "m-t4n59ju53utcnf1a9rka"  //Singapore
    default = "m-j6c0ynur3vhegggbjqqm"  //HongKong
}

variable "image-webserver1-name" {
    default = "web-server-1"
}

variable "image-webserver2-name" {
    default = "web-server-2"
}

variable "image-webserver1-id" {
    # default = "m-t4n6sctos4o76zuat9wl" //Singapore
    default = "m-j6cggjmd5y51gcrujajs"  //HongKong
}

variable "image-webserver2-id" {
    #default = "m-t4n42c1i4urwxi5rqqea" //Singapore
    default = "m-j6ccumk9lw77usu3bg51"  //HongKong
}

variable "demo-vpc-cidr" {
    default = "10.0.0.0/16"
}

variable "mgmt-vswitch-cidr" {
    default = "10.0.4.0/24"
}

variable "mgmt-vswitch-cidr-2" {
    default = "10.0.7.0/24"
}

variable "demo-trust-vswitch-cidr" {
    default = "10.0.6.0/24"
}

variable "demo-trust-vswitch-cidr-2" {
    default = "10.0.9.0/24"
}
variable "demo-untrust-vswitch-cidr" {
    default = "10.0.5.0/24"
}

variable "demo-untrust-vswitch-cidr-2" {
    default = "10.0.8.0/24"
}
variable "mgmt-ip" {
    default = "10.0.4.20"
}

variable "mgmt-ip-2" {
    default = "10.0.7.20"
}
variable "trust-ip" {
    default = "10.0.6.20"
}
variable "trust-ip-2" {
    default = "10.0.9.20"
}
variable "untrust-ip" {
    default = "10.0.5.20"
}
variable "untrust-ip-2" {
    default = "10.0.8.20"
}
variable "trust-router-ip" {
    default = "10.0.6.253"
}

variable "trust-router-ip-2" {
    default = "10.0.9.253"
}
variable "untrust-router-ip" {
    default = "10.0.5.253"
}
variable "untrust-router-ip-2" {
    default = "10.0.8.253"
}
variable "web-server-1" {
    default = "10.0.6.50"
}
variable "web-server-2" {
    default = "10.0.9.50"
}
variable "name" {
    default = "VMGW_Demo-1"
}

variable "name-2" {
    default = "VMGW_Demo-2"
}
variable "region" {
    #default = "ap-southeast-1"  #Singapore
    default = "cn-hongkong"      #HongKong
}

variable "default_egress_route" {
  type    = string
  default = "0.0.0.0/0"
}
