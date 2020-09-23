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


# Add interfaces to the firewall
##################################

resource "panos_ethernet_interface" "e1" {
    name = "ethernet1/1"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
    create_dhcp_default_route = false
    comment = "Trust Interface"
}

resource "panos_ethernet_interface" "e2" {
    name = "ethernet1/2"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
    create_dhcp_default_route = false
    comment = "Untrust Interface"
}


# Add a new zones to the firewall
##################################
resource "panos_zone" "Untrust" {
    name = "Untrust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.e2.name}" ]
}

resource "panos_zone" "Trust" {
    name = "Trust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.e1.name}" ]
}

# Configure Virtual Router
##################################
resource "panos_virtual_router" "vr" {
    name = "default"
    static_dist = 15
    interfaces = ["ethernet1/1", "ethernet1/2"]

    depends_on = [ "panos_ethernet_interface.e1","panos_ethernet_interface.e2"]
}
#Conifgure Static Routes
#########################
resource "panos_static_route_ipv4" "Route-To-WebServer1" {
    name = "Route-To-WebServer1"
    virtual_router = "${panos_virtual_router.vr.name}"
    destination = "${var.Route-To-WebServer1}"
    next_hop = "${var.Route-To-WebServer-nexthop}"
    interface = "${panos_ethernet_interface.e1.name}"
    depends_on = ["panos_virtual_router.vr"]
}

resource "panos_static_route_ipv4" "Route-To-WebServer2" {
    name = "Route-To-WebServer2"
    virtual_router = "${panos_virtual_router.vr.name}"
    destination = "${var.Route-To-WebServer2}"
    next_hop = "${var.Route-To-WebServer-nexthop}"
    interface = "${panos_ethernet_interface.e1.name}"
    depends_on = ["panos_virtual_router.vr"]
}

resource "panos_static_route_ipv4" "Route-to-Default" {
    name = "Route-to-Default"
    virtual_router = "${panos_virtual_router.vr.name}"
    destination = "0.0.0.0/0"
    interface = "${panos_ethernet_interface.e2.name}"
    next_hop = "${var.Route-to-Default-nexthop}"
    depends_on =["panos_virtual_router.vr"]
}




#FW NAT Rules
##################################

resource "panos_nat_rule_group" "SRC-NAT-Internet" {
    rule {
        name = "SRC-NAT-Internet"
        original_packet {
            source_zones = ["${panos_zone.Trust.name}"]
            destination_zone = "${panos_zone.Untrust.name}"
            source_addresses = ["any"]
            destination_addresses = ["any"]
        }
        translated_packet {
            source {
                dynamic_ip_and_port {
                    interface_address {
                        interface = "${panos_ethernet_interface.e2.name}"
                       
                    }
                }
            }
            destination {
                
            }
        }
    }
}



resource "panos_nat_rule_group" "web-nat" {
    rule {
        name = "NAT-Web-In"
        original_packet {
            source_zones = ["${panos_zone.Untrust.name}"]
            destination_zone = "${panos_zone.Untrust.name}"
            destination_interface = "${panos_ethernet_interface.e2.name}"
            source_addresses = ["any"]
            destination_addresses = ["10.0.5.20"]
            service = "service-http"
        }
        translated_packet {
            source {}
            destination {
                static_translation {
                    address = "var.slb_ip"
                    port = 80
                }
            }
        }
    }
}

#FW Rules
#These are here as an example.  ANY-ANY rule is not suggested but 
#this provides an example
##################################

resource "panos_security_policy" "fw-rules" {
    rule {
        name = "allow-all-traffic-out"
        source_zones = ["Trust"]
        source_addresses = ["any"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["Untrust"]
        destination_addresses = ["any"]
        applications = ["any"]
        services = ["any"]
        categories = ["any"]
        action = "allow"
    }
    rule {
        name = "allow-web-in"
        source_zones = ["Untrust"]
        source_addresses = ["any"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["Trust"]
        destination_addresses = ["any"]
        applications = ["web-browsing"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
}
resource "null_resource" "run_cmd" {
  provisioner "local-exec" {
    command = "expect ./fwcommit.expect ${var.fwip_1} ${var.fwusername} ${var.fwpassword}" 
    }
   depends_on = [ "panos_nat_rule_group.SRC-NAT-Internet", "panos_nat_rule_group.web-nat"]
}