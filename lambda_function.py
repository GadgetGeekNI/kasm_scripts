# ---------------------------------------------------------------------------- #
#                                  What doing?                                 #
# ---------------------------------------------------------------------------- #
# The objective of this script is to rotate the kasm autoscaling user IAM 
# credentials and programatically update them in an configurations within a Kasm
# environment.
# NOTE: For this script to work successfully, you need to make sure your 
# variables for the API are present on your host.
# Please note this is an example and not real credentials.
#  export KASM_API_KEY='sup3rDup3RS3cr3t!'; export KASM_API_KEY_SECRET='123451235123!

import requests
import os
import json
#AWS
import boto3
from botocore.exceptions import ClientError
import datetime
from base64 import b64decode
#Slack
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# ---------------------------------------------------------------------------- #
#                                   AWS Vars                                   #
# ---------------------------------------------------------------------------- #

target_rotation_usernames= ["kasm-prod-agent-autoscaling-iam-user"]
iam_days_before_rotation = 30

aws_access_key_id = 'AWS_ACCESS_KEY_ID'
aws_secret_access_key = 'AWS_SECRET_ACCESS_KEY'
# Create a IAM Boto Client
iam_client = boto3.client('iam')

# ---------------------------------------------------------------------------- #
#                                   Kasm Vars                                  #
# ---------------------------------------------------------------------------- #

# Set up the endpoint URL and API key
host_url = os.environ['HOST_URL']
api_url = host_url + "/api/admin/"
try:
    kasm_api_key = os.environ['KASM_API_KEY']
    kasm_api_key_secret = os.environ['KASM_API_KEY_SECRET']
except KeyError:
    print("Please ensure that the KASM_API_KEY and KASM_API_KEY_SECRET environment variables are set.")

# Header & Payload Values.
# Define the query payload
get_query_payload = {
    "api_key": kasm_api_key,
    "api_key_secret": kasm_api_key_secret
}
# Define the headers
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}

# ---------------------------------------------------------------------------- #
#                                  Slack Vars                                  #
# ---------------------------------------------------------------------------- #
# Slack Vars
slack_client = WebClient(token=os.environ['SLACK_TOKEN'])
slack_channel_id = token=os.environ['SLACK_CHANNEL_ID']

# ---------------------------------------------------------------------------- #
#                                     Kasm                                     #
# ---------------------------------------------------------------------------- #

# Query the Kasm API and get all VM Provider Configs
def get_vm_provider_configs():
    # Make the POST request with the API key and secret
    response = requests.post(api_url + 'get_vm_provider_configs' , headers=headers, data=json.dumps(get_query_payload))

    # Check the response status code
    if response.status_code == 200:
        # Parse the JSON response
        try:
            response_data = response.json()
            vm_provider_configs = response_data.get('vm_provider_configs', [])  # Access the list of configurations
            return vm_provider_configs
        except json.JSONDecodeError:
            print("Failed to parse JSON response.")
    else:
        print(f"Request failed with status code {response.status_code}")
        print(response.text)

# Loop over the list of vm provider configs and match the existing aws key against the one that was rotated from the IAM function.
# This will allow us to use multi region, multi account configs in future without having to worry about overwriting configs not applicable
# to this function.
def get_matching_vm_provider_config_ids(user_iam_details, vm_provider_configs):
    # Create an empty list to store matching configuration data
    matching_vm_provider_configs = []

    # Create a set of AWS access keys from user IAM details
    user_access_keys = set(user_iam['AccessKeyId'] for user_iam in user_iam_details)

    for config in vm_provider_configs:
        if config['aws_access_key_id'] in user_access_keys:
            # Append the entire configuration dictionary
            matching_vm_provider_configs.append(config)

    return matching_vm_provider_configs

# Update the AWS Key and Secret Key for each VM Provider Config found.
def update_vm_provider_configs(matching_vm_provider_configs, generated_access_key, generated_secret_key):
    updated_vm_provider_names = []  # Initialize a list to store updated configurations

    # Check if matching_vm_provider_configs is not empty
    if matching_vm_provider_configs:
        # Iterate through each configuration and create a payload for updating AWS keys
        for config in matching_vm_provider_configs:
            # Create a payload for updating AWS keys
            update_aws_keys_payload = {
                "target_vm_provider_config": {
                    'aws_access_key_id': generated_access_key,  # Existing access key
                    'aws_secret_access_key': generated_secret_key,  # Existing secret key
                    'vm_provider_name': 'aws',
                    'vm_provider_config_id': config.get('vm_provider_config_id', '')  # Use vm_provider_config_id
                },
                "api_key": kasm_api_key,
                "api_key_secret": kasm_api_key_secret
            }

            # Send a request to update AWS keys using update_aws_keys_payload
            update_response = requests.post(api_url + 'update_vm_provider_config', headers=headers, data=json.dumps(update_aws_keys_payload))

            # Check the response status code and handle the response as needed
            if update_response.status_code == 200:
                # Get the config name and id for return
                updated_vm_provider_config_name = config.get('vm_provider_config_name', '')

                # Append the config name and id to the respective lists
                updated_vm_provider_names.append(updated_vm_provider_config_name)

                # Print out a success message
                print(f"Updated AWS keys for config: {str(updated_vm_provider_config_name)}")
            else:
                print(f"Failed to update AWS keys for config: {config.get('vm_provider_config_name', '')}, Status code: {update_response.status_code}")
    else:
        print("No VM provider configs found.")

    return updated_vm_provider_names  # Return the lists of names and ids

# ---------------------------------------------------------------------------- #
#                          AWS IAM Credential Rotation                         #
# ---------------------------------------------------------------------------- #

# Get IAM User Details.
def list_access_key(user, days_filter, status_filter):
    keydetails=iam_client.list_access_keys(UserName=user)
    key_details={}
    user_iam_details=[]

    # Some user may have 2 access keys.
    for keys in keydetails.get('AccessKeyMetadata'):
        # Get Time/Date to compare against IAM Users last regeneration date.
        if (days:=time_diff(keys['CreateDate'])) >= days_filter and keys['Status']==status_filter:
            key_details['UserName']=keys['UserName']
            key_details['AccessKeyId']=keys['AccessKeyId']
            key_details['days']=days
            key_details['status']=keys['Status']
            user_iam_details.append(key_details)
            key_details={}
        else: 
            print('IAM Key for '+ user +' is less than ' + str(iam_days_before_rotation) + ' days old. No action taken.')

    return user_iam_details

# Get Time/Date to compare against IAM Users last regeneration date.
def time_diff(keycreatedtime):
    now=datetime.datetime.now(datetime.timezone.utc)
    diff=now-keycreatedtime
    return diff.days

# Regenerate IAM Key.
def create_key(username):
    access_key_metadata = iam_client.create_access_key(UserName=username)
    generated_access_key = access_key_metadata['AccessKey']['AccessKeyId']
    generated_secret_key = access_key_metadata['AccessKey']['SecretAccessKey']
    print(generated_access_key + " has been created.")
    return generated_access_key,generated_secret_key

# Disable Existing IAM Key if date greater than tolerance.
def disable_key(access_key, username):
    try:
        iam_client.update_access_key(UserName=username, AccessKeyId=access_key, Status="Inactive")
        print(access_key + " has been disabled.")
    except ClientError as e:
        print("The access key with id %s cannot be found" % access_key)

# Delete Existing IAM Key if date greater than tolerance.
def delete_key(access_key, username):
    try:
        iam_client.delete_access_key(UserName=username, AccessKeyId=access_key)
        print (access_key + " has been deleted.")
    except ClientError as e:
        print("The access key with id %s cannot be found" % access_key)

def send_slack_failure_notification(error_message):
    try:
        # Call the conversations.list method using the WebClient
        slack_client.chat_postMessage(
            channel=slack_channel_id,
            text=f"An unexpected error occurred which resulted in the IAM key rotation failing :\n\n*Error Message: {error_message}*"
        )
    except SlackApiError as e:
        print(f"Error: {e}")

# ---------------------------------------------------------------------------- #
#                                Lambda Function                               #
# ---------------------------------------------------------------------------- #

# Run the Lambda.
def lambda_handler(event, context):
    try:
        non_existent_users = []
        for user in target_rotation_usernames:
            try:
                iam_client.get_user(UserName=user)
            except iam_client.exceptions.NoSuchEntityException:
                print(f"User '{user}' does not exist. Skipping policy attachment.")
                non_existent_users.append(user)

        # Attach the policy to the existing users
        existing_users = set(target_rotation_usernames) - set(non_existent_users)
        if existing_users:
            for user in existing_users:
                # Save the Username for this loop
                found_username = user
                user_iam_details=list_access_key(user=user,days_filter=iam_days_before_rotation,status_filter='Active')
                for _ in user_iam_details:
                    # ------------------------------------ AWS ----------------------------------- #
                    # Disable Existing IAM Key if date greater than tolerance.
                    disable_key(access_key=_['AccessKeyId'], username=_['UserName'])
                    # Delete Existing IAM Key if date greater than tolerance.
                    delete_key(access_key=_['AccessKeyId'], username=_['UserName'])
                    # Regenerate IAM Key.
                    generated_access_key, generated_secret_key = create_key(username=_['UserName'])
                    # Get Kasm AutoScaling Config ID
                    vm_provider_configs = get_vm_provider_configs()
                    # Match Rotated AWS Key against Kasm AWS Key
                    matching_vm_provider_configs=get_matching_vm_provider_config_ids(user_iam_details, vm_provider_configs)
                    # Send new Key to Kasm
                    update_vm_provider_configs(matching_vm_provider_configs,generated_access_key,generated_secret_key)
                else:
                    print("No action taken.")
        # Print a message about non-existent users
        if non_existent_users:
                print(f"Skipping IAM Rotation for non-existent users: {', '.join(non_existent_users)}") 
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        send_slack_failure_notification(str(e))
