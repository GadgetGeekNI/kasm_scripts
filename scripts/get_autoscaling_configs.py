# ---------------------------------------------------------------------------- #
#                                  What doing?                                 #
# ---------------------------------------------------------------------------- #
# The objective of this script is to get a list of all Autoscaling Provider 
# configurations within a Kasm environment.
# NOTE: For this script to work successfully, you need to make sure your 
# variables for the API are present on your host.
# Please note this is an example and not real credentials.
#  export KASM_API_KEY='sup3rDup3RS3cr3t!'; export KASM_API_KEY_SECRET='123451235123!; export KASM_HOST_URL='https://kasm.example.com'

import requests
import os
import json

# Set up the endpoint URL and API key
host_url = os.environ['KASM_HOST_URL']
api_url = host_url + "/api/admin/"
try:
    kasm_api_key = os.environ['KASM_API_KEY']
    kasm_api_key_secret = os.environ['KASM_API_KEY_SECRET']
except KeyError:
    print("Please ensure that the KASM_API_KEY and KASM_API_KEY_SECRET environment variables are set.")

# Header & Payload Values.
# Define the headers
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}
# Define the payload
payload = {
    "api_key": kasm_api_key,
    "api_key_secret": kasm_api_key_secret
}

def get_vm_provider_config():
    # Make the POST request with the API key and secret
    response = requests.post(api_url + 'get_vm_provider_configs' , headers=headers, data=json.dumps(payload))

    # Check the response status code
    if response.status_code == 200:
        # Parse the JSON response
        try:
        # PLACEHOLDER
            vm_provider_config = response.json()
            return vm_provider_config
        except json.JSONDecodeError:
            print("Failed to parse JSON response.")
    else:
        print(f"Request failed with status code {response.status_code}")
        print(response.text)

def main():
    try:
        vm_provider_config = get_vm_provider_config()
        print(vm_provider_config)
    except Exception as e:
        raise  # Reraise the exception for debugging purposes

main()