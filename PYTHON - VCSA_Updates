# -*- coding: utf-8 -*-
## Script Information: 
# Description           : Get available updates on VCSA via VMware API 
# API supported version : v7.0 U2 or later (https://developer.vmware.com/docs/vsphere-automation/latest/appliance/)
# Need administrator privilege on VCSA to use VMware API
# Date                  : 08 october 2021

import json
import sys
import requests

from prtg.sensor.result import CustomSensorResult
from prtg.sensor.units import ValueUnit
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Function: print PRTG json output and exit script with exitcode
def csr_output(csr,exitcode):
    print(csr.json_result)
    sys.exit(exitcode)

# Function: print PRTG json output with exception message
def script_exception(e,exitcode):   
        csr       = CustomSensorResult(text="Python Script execution error")
        csr.error = f"Python Script execution error: {str(e)}"
        csr_output(csr,exitcode)

if __name__ == "__main__":
    # Get placeholders with the servername and credentials
    data        = json.loads(sys.argv[1])
    server      = data['host']
    username    = data['linuxloginusername']
    password    = data['linuxloginpassword'] 

    # Define exitcode and initialize exitcode  
    ExitError = 1
    ExitOK    = 0
    exitcode  = ExitError   

    # Define API URL and requests timeout
    base_url         = f'https://{server}'
    URL_update       = f'https://{server}/api/appliance/update/pending?source_type=LOCAL_AND_ONLINE' 
    requests_timeout = 30

    # Get VMware API session token
    try:
        resp = requests.post(f'{base_url}/rest/com/vmware/cis/session',auth=(username,password),verify=False,timeout=requests_timeout)
        if resp.status_code != requests.codes['OK']:
            output   = f'Error! API responded with:{resp.status_code} {resp.reason}'
            exitcode = ExitError
            csr      = CustomSensorResult(text = output)
            csr.add_channel(name="Available Updates", value=resp.status_code, is_float=True, is_limit_mode=True,  limit_min_error=0, limit_max_error=0.5)
            csr_output(csr,exitcode)        
        vmware_api_session_token = resp.json()['value']             
    except Exception as e:
        script_exception(e,exitcode)
    
    # Get available updates
    Headers_update = {
        'Content-Type': 'application/json',
        'vmware-api-session-id':  vmware_api_session_token
    }
    try:
        r_update   = requests.get(URL_update,headers=Headers_update,verify=False,timeout=requests_timeout)
        if r_update.status_code != requests.codes['OK']:
            if r_update.status_code == requests.codes['not_found']:
                # Update not found
                output                 = f'No available Updates {r_update.status_code} {r_update.reason}'
                update_available_count = 0
                exitcode = ExitOK
                csr                    = CustomSensorResult(text=output)
                csr.add_channel(name="Available Updates", value=update_available_count, is_float=True, is_limit_mode=True,  limit_min_error=0, limit_max_error=0.5)
            else:
                output   = f'{r_update.status_code} {r_update.reason}'
                exitcode = ExitError
                csr = CustomSensorResult(text=output)
            csr_output(csr,exitcode)        
    except Exception as e:
        script_exception(e,exitcode)        
    
    # Return a list of available severity updates and delete session
    try:
        j                      = r_update.json()
        update_available_count = len(j)
        output                 = [f"Severity:{update['severity']} Name:{update['name']}" for update in j]
        exitcode               = ExitOK
        csr                    = CustomSensorResult(text=f'{update_available_count} updates available {output}')
        csr.add_channel(name="Available Updates", value=update_available_count, is_float=True, is_limit_mode=True, limit_min_error=0, limit_max_error=0.5)
        # Delete session
        Headers_delete = {
            'vmware-api-session-id':  vmware_api_session_token
        }
        r_delete   = requests.delete(f'{base_url}/api/session',headers=Headers_delete,verify=False,timeout=requests_timeout)        
        csr_output(csr,exitcode)
    except Exception as e:
        script_exception(e,exitcode)
