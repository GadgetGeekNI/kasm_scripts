import requests

# Set up the endpoint URL and API key
host_url = "https://khaos.example.com"
api_url = host_url + "/api/public/"
api_key = "12312513"
api_key_secret = "12345123123" # This is going to be deleted when testing is done. 
headers = {
    "Authorization": f"Token {api_key}",
    "X-Auth-Secret": api_key_secret,
    "Content-Type": "application/json"
}

def get_all_users():
    # Make the POST request with the API key and secret
    payload = {
        "api_key": api_key,
        "api_key_secret": api_key_secret
    }
    response = requests.post(api_url+"get_users", headers=headers, json=payload)
    # Check if the request was successful
    if response.status_code == 200:
        # Get the list of users from the response JSON
        users = response.json()["users"]
        # Extract the usernames from the user objects and return the list of usernames
        usernames = [user["username"] for user in users]
        return usernames
    else:
        # If the request failed, raise an exception with the error message
        raise Exception(f"Error retrieving users: {response.status_code} {response.text}")

def main():
    try:
        existing_usernames = get_all_users()
        print("Existing users:")
        for username in existing_usernames:
            print(username)
    except Exception as e:
        print(e)

main()