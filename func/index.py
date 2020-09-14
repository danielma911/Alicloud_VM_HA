# -*- coding: utf-8 -*-
import argparse
import logging
import os
import subprocess
import sys
import uuid
import xml.etree.ElementTree as ET
import requests
import urllib3
import json, random, string, time
from aliyunsdkcore import client
from aliyunsdkvpc.request.v20160428.AssociateEipAddressRequest import AssociateEipAddressRequest
from aliyunsdkvpc.request.v20160428.UnassociateEipAddressRequest import UnassociateEipAddressRequest
from aliyunsdkvpc.request.v20160428.DescribeEipAddressesRequest import DescribeEipAddressesRequest
from aliyunsdkcore.auth.credentials import StsTokenCredential
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkvpc.request.v20160428.CreateRouteEntryRequest import CreateRouteEntryRequest
from aliyunsdkvpc.request.v20160428.DeleteRouteEntryRequest import DeleteRouteEntryRequest
from aliyunsdkvpc.request.v20160428.DescribeEipAddressesRequest import DescribeEipAddressesRequest



# To enable the initializer feature (https://help.aliyun.com/document_detail/158208.html)
# please implement the initializer function as below：
# def initializer(context):
#   logger = logging.getLogger()
#   logger.info('initializing')
logger = logging.getLogger()
clt = None
def handler(event, context):
    api_key = os.environ.get('API_KEY')
    regionId = os.environ.get('REGION_ID')
    eipId = os.environ.get('EIP_ID')
    standbyEcsId = os.environ.get('BACKUPNGFW_ID')
    ecsInstanceId = os.environ.get('PRIMARYNGFW_ID')
    public_eni_pri = os.environ.get('PUB_PRI_ENI')
    public_eni_bak = os.environ.get('PUB_BAK_ENI')
    eip = os.environ.get('EIP')
    routeTbID = os.environ.get('ROUTETB_ID')
    primary_eni = os.environ.get('PRIMARY_ENI')
    backup_eni = os.environ.get('BACKUP_ENI')
    fwMgtIP = os.environ.get('PRIMARYNGFWMGMT_IP')
    # username = "admin"
    # password = "admin"
    #api_key = getApiKey(fwMgtIP, username, password)
    # api_key = "LUFRPT0wVG0wR1pUb3k2akZnNXR6VkcxSG9sY3BzOHM9M0NCZkhWTFhSK3lmaTk4SEc3bXE0VlloaEJpVmt0cVVQNXRJcS9sVlk2ST0="

    creds = context.credentials
    sts_token_credential = StsTokenCredential(creds.access_key_id, creds.access_key_secret, creds.security_token)
    
    global clt
    clt = client.AcsClient(region_id=regionId, credential=sts_token_credential)
    

    while True:
      err = getFirewallStatus(fwMgtIP, api_key)
      if err == 'cmd_error':
        logger.info("Command error from fw ")
        break

      elif err == 'no':
        logger.info("FW is down")
        
        #return ecsInstanceId
        if checkBackup(eip, public_eni_bak):
            break
        move_eip(public_eni_pri, public_eni_bak, eipId, regionId) # move eip to standbyEcs
        if deleteRouteEntry(routeTbID, primary_eni):
            logger.info("Route Entry Deleted - Primary")
            time.sleep(10)
        else:
            logger.error("Route Entry Delete Fail - Primary")
        if createRouteEntry(routeTbID, backup_eni):
            logger.info("Route Entry Added - Backup")
        else:
            logger.error("Route Entry Add Fail - Backup")

        break

      elif err == 'almost':
        logger.info("MGT up waiting for dataplane")
        time.sleep(20)
        pass

      elif err == 'yes':
        logger.info("FW is up")
        #time.sleep(20)
        if checkBackup(eip, public_eni_bak):
           logger.info("Moving back to Primary")
           move_eip(public_eni_bak, public_eni_pri, eipId, regionId)
           if deleteRouteEntry(routeTbID, backup_eni):
              logger.info("Route Entry Deleted - Backup")
              time.sleep(10)
           else:
              logger.error("Route Entry Delete Fail - Backup")
           if createRouteEntry(routeTbID, primary_eni):
              logger.info("Route Entry Added - Primary")
           else:
              logger.error("Route Entry Add Fail - Primary")
        break
    
    return err

def deleteRouteEntry(routeTbID, NextHopId):
    request = DeleteRouteEntryRequest()
    request.set_accept_format('json')
    request.set_RouteTableId(routeTbID)
    request.set_DestinationCidrBlock("0.0.0.0/0")
    request.set_NextHopId(NextHopId)
    response = _send_request(request)
    if isinstance(response, dict) and "RequestId" in response:
      logger.info("Delete Defualt Route in Route Table {} to ENI {} Successed".format(routeTbID, NextHopId))
      return True
    else:
      logger.error("Delete Defualt Route in Route Table {} to ENI {} failed".format(routeTbID, NextHopId))
      return False


def createRouteEntry(routeTbID, NextHopId):
    request = CreateRouteEntryRequest()
    request.set_DestinationCidrBlock("0.0.0.0/0")
    request.set_RouteTableId(routeTbID)
    request.set_NextHopId(NextHopId)
    request.set_NextHopType("NetworkInterface")
    response = _send_request(request)
    if isinstance(response, dict) and "RequestId" in response:
      logger.info("Create Defualt Route in Route Table {} to ENI {} Successed".format(routeTbID, NextHopId))
      return True
    else:
      logger.error("Create Defualt Route in Route Table {} to ENI {} failed".format(routeTbID, NextHopId))
      return False

    

def send_request(call):

    """
    Handles sending requests to API
    :param call: url
    :return: Retruns result of call. Will return response for codes between 200 and 400.
             If 200 response code is required check value in response
    """
    headers = {'Accept-Encoding' : 'None',
               'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) '
                              'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}

    try:
        r = requests.get(call, headers = headers, verify=False, timeout=5)
        r.raise_for_status()
    except requests.exceptions.HTTPError as errh:
        '''
        Firewall may return 5xx error when rebooting.  Need to handle a 5xx response 
        '''
        logger.debug("DeployRequestException Http Error:")
        raise DeployRequestException("Http Error:")
    except requests.exceptions.ConnectionError as errc:
        logger.debug("DeployRequestException Connection Error:")
        raise DeployRequestException("Connection Error")
    except requests.exceptions.Timeout as errt:
        logger.debug("DeployRequestException Timeout Error:")
        raise DeployRequestException("Timeout Error")
    except requests.exceptions.RequestException as err:
        logger.debug("DeployRequestException RequestException Error:")
        raise DeployRequestException("Request Error")
    else:
        return r
        
def getFirewallStatus(fwIP, api_key):
    fwip = fwIP

    """
    Gets the firewall status by sending the API request show chassis status.
    :param fwMgtIP:  IP Address of firewall interface to be probed
    :param api_key:  Panos API key
    """

    url = "https://%s/api/?type=op&cmd=<show><chassis-ready></chassis-ready></show>&key=%s" % (fwip, api_key)
    # Send command to fw and see if it times out or we get a response
    logger.info("Sending command 'show chassis status' to firewall")
    try:
        response = requests.get(url, verify=False, timeout=10)
        response.raise_for_status()
    except requests.exceptions.Timeout as fwdownerr:
        logger.debug("No response from FW. So maybe not up!")
        return 'no'
        # sleep and check again?
    except requests.exceptions.HTTPError as fwstartgerr:
        '''
        Firewall may return 5xx error when rebooting.  Need to handle a 5xx response
        raise_for_status() throws HTTPError for error responses
        '''
        logger.info("Http Error: {}: ".format(fwstartgerr))
        return 'cmd_error'
    except requests.exceptions.RequestException as err:
        logger.debug("Got RequestException response from FW. So maybe not up!")
        return 'cmd_error'
    else:
        logger.debug("Got response to 'show chassis status' {}".format(response))

        resp_header = ET.fromstring(response.content)
        logger.debug('Response header is {}'.format(resp_header))

        if resp_header.tag != 'response':
            logger.debug("Did not get a valid 'response' string...maybe a timeout")
            return 'cmd_error'

        if resp_header.attrib['status'] == 'error':
            logger.debug("Got an error for the command")
            return 'cmd_error'

        if resp_header.attrib['status'] == 'success':
            # The fw responded with a successful command execution. So is it ready?
            for element in resp_header:
                if element.text.rstrip() == 'yes':
                    logger.info("FW Chassis is ready to accept configuration and connections")
                    return 'yes'
                else:
                    logger.info("FW Chassis not ready, still waiting for dataplane")
                    time.sleep(10)
                    return 'almost'

def checkBackup(eip, backup_eni):
    request = DescribeEipAddressesRequest()
    request.set_accept_format('json')
    request.set_EipAddress(eip)
    response = clt.do_action_with_exception(request)
    response = bytes.decode(response)
    if backup_eni in response:
        logger.info("Running on Backup NGFW")  
        return True
    else:
        logger.info("Running on Primary NGFW")
        return False

def getEipStatus(eip, regionId):
    request = DescribeEipAddressesRequest()
    request.set_AllocationId(eip)
    request.add_query_param("RegionId", regionId)
    response = _send_request(request)
    if isinstance(response, dict) and "RequestId" in response:
      EipAddresses = response.get('EipAddresses', {})
      EipAddress = EipAddresses['EipAddress'][0]
      status = EipAddress['Status']
      return status
    else:
      logger.error("getEipAddressDesc {} fail".format(eip))
def unAssociateEip(eni_id, eip):
    request = UnassociateEipAddressRequest()
    request.set_AllocationId(eip)
    #request.set_InstanceType('EcsInstance')
    request.set_InstanceId(eni_id)
    request.set_InstanceType("NetworkInterface")
    response = _send_request(request)
    if isinstance(response, dict) and "RequestId" in response:
      logger.info("UnassociateEipAddress {} from {} succ".format(eni_id, eip))
    else:
      logger.error("UnassociateEipAddress {} from {} fail".format(eni_id, eip))
def associateEip(eni_id, eip):
    associte_request = AssociateEipAddressRequest()
    associte_request.set_AllocationId(eip)
    associte_request.set_InstanceType('NetworkInterface')
    associte_request.set_InstanceId(eni_id)
    associte_response = _send_request(associte_request)
    if isinstance(associte_response, dict) and "RequestId" in associte_response:
      logger.info("AssociateEipAddress {} to {} succ".format(eip, eni_id))
      return True
    return False
def move_eip(from_eni, to_eni, eip, regionId):
    unAssociateEip(from_eni, eip)
    # wait unAssociateEip ...
    time.sleep(3)
    # retry 30s util sucess
    for i in range(10):
      eip_status = getEipStatus(eip, regionId).lower()
      if eip_status == 'available':
        if associateEip(to_eni, eip):
          logger.info("AssociateEipAddress {} to {} succ".format(eip, to_eni))
          return
      else:
        logger.info("eip status = {}".format(eip_status))
        time.sleep(3)
    logger.info("AssociateEipAddress {} to {} fail".format(eip, to_eni))
# send open api request
def _send_request(request):
    request.set_accept_format('json')
    try:
        response_str = clt.do_action_with_exception(request)
        logger.info(response_str)
        response_detail = json.loads(response_str)
        return response_detail
    except Exception as e:
        logger.error(e)