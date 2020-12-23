#!/usr/bin/env python3

import requests
import xml.etree.ElementTree as ET
import urllib3
from python_terraform import Terraform
import time
import paramiko
from contextlib import closing

def wait_until_channel_endswith(channel, endswith, wait_in_seconds=15):
    timeout = time.time() + wait_in_seconds
    read_buffer = b''
    while not read_buffer.endswith(endswith):
        if channel.recv_ready():
           read_buffer += channel.recv(4096)
        elif time.time() > timeout:
            raise TimeoutError(f"Timeout while waiting for '{endswith}' on the channel")
        else:
            time.sleep(1)

def change_default_password_over_ssh(host, username, current_password, new_password):
    with closing(paramiko.SSHClient()) as ssh_connection:
        ssh_connection.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_connection.load_system_host_keys()

        while True:
            try:
                ssh_connection.connect(hostname=host, username=username, password=current_password)
                break
            except Exception as e:
                print("Waiting for vm-series to be available ...")

        ssh_channel = ssh_connection.invoke_shell()

        wait_until_channel_endswith(ssh_channel, b'Enter old password : ')
        ssh_channel.send(f'{current_password}\n')
        #print("Entered old Password")

        wait_until_channel_endswith(ssh_channel, b'Enter new password : ')
        ssh_channel.send(f'{new_password}\n')
        #print("Entered new Password")

        wait_until_channel_endswith(ssh_channel, b'Confirm password   : ')
        ssh_channel.send(f'{new_password}\n')
        #print("Entered confirm Password")

        wait_until_channel_endswith(ssh_channel, b'Please change your password prior to deployment.\r\n')
        #print("Password changed")


urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

working_dir = "./"

tf = Terraform(working_dir=working_dir)
outputs = tf.output()
fw1_mgmt = outputs['VM-Series-MGMTIP']['value']
fw2_mgmt = outputs['VM-Series-MGMTIP-2']['value']

# fw1_mgmt = "47.242.173.151"
# fw2_mgmt = "47.242.231.19"
username = "admin"
default_password = outputs['password_default']['value']
new_password = outputs['password_new']['value']
# default_password = "admin"
# new_password = "Paloalto123!"

# Wait for VM-Series to complete booting process
time.sleep(480)

change_default_password_over_ssh(fw1_mgmt, username, default_password, new_password)
change_default_password_over_ssh(fw2_mgmt, username, default_password, new_password)

print("Default Password Has been updated with New")