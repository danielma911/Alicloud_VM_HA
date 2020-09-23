# Copyright (c) 2018, Palo Alto Networks
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.



variable "slb_ip" {
    default = "Update_The_Internal_SLB_IP_address_Here"
}


#Information for the PANW Provider
####################################
variable fwip_1 {
    default = "Update_NGFW_1_MGMT_address_Here""
}
variable fwusername {
    default = "admin"
}
variable fwpassword {
    default = "admin"  #This is Default, change this if the ngfw password has been changed.
}

# Configure the panos provider
##################################
provider "panos" {
    hostname = "${var.fwip_1}"
    username = "${var.fwusername}"
    password = "${var.fwpassword}"
}


#Route to WebServer
###################################
variable "Route-To-WebServer-nexthop" {
    default = "10.0.6.253"     
}

variable "Route-To-WebServer1" {
    default = "10.0.6.0/24"     
}

variable "Route-To-WebServer2" {
    default = "10.0.9.0/24"     
}
#Route to default
##################################
variable "Route-to-Default-nexthop" {
    default = "10.0.5.253"
}



