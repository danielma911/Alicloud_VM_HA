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


# Configure the Alicloud Provider for R1 region
####################################
variable "access_key" {
    default = "Update Here"
}

variable "secret_key" {
    default = "Update Here"
}

variable "region" {
    default = "cn-hongkong"
}

variable "slb_ip" {
    default = "Please Update the Internal SLB IP Address Here"
}
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
  alias      = "r1"
}


#Information for the PANW Provider
####################################
variable fwip_1 {
    default = "Update NGFW 1 management IP address Here"
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
    alisa    = "ngfw"
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



