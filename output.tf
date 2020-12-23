output "password_default" {
  value = var.password
  sensitive = true
}

output "password_new" {
  value = var.new_password
}

output "VM-Series-MGMTIP" {
  value = alicloud_eip.MGMT-EIP.ip_address
}
output "VM-Series-MGMTIP-2" {
  value = alicloud_eip.MGMT-EIP-2.ip_address
}
output "SLB-IP-Address" {
  value = "${module.slb.this_slb_address}"  
}
output "VM-Series-UNTRUSTIP" {
  value = "${alicloud_eip.UNTRUST-EIP.ip_address} *** Please manually attach this IP to Untrust ENI. *** \n\n"
}
