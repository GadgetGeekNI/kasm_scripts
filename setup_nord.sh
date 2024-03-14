#!/bin/env bash
# Config first so nothing is skipped

# ---------------------------------------------------------------------------- #
#                                    Config                                    #
# ---------------------------------------------------------------------------- #
# Intentionally set in the home directory as it is then saved by a persistent
# user profile.
profile_location="/home/kasm-user/openvpn"
credentials_file="/home/kasm-user/openvpn/auto-auth.txt"
ovpn_tcp_directory="/etc/openvpn/ovpn_tcp"

# Ensure the profile exists locally.
mkdir -p $profile_location

# Flag variable to track first run to not dump the top nomenclature out every time
first_run=true

# ---------------------------------------------------------------------------- #
#                                   Main Menu                                  #
# ---------------------------------------------------------------------------- #

vpn_setup_menu() {
  clear
  # Nomenclature to only be printed the first time
  if $first_run; then
    echo "Welcome!"
    echo "This script is intended to make your initial VPN configuration easier by automating the manual tasks!"
    echo "Please note..."
    echo "This is as a cookie-cutter script for general use cases and may not fit specific requirements."
    echo " "
    first_run=false
  fi
  # Prompt for menu selection
  echo "Please select an option:"
  echo "1 : VPN Setup Menu.(Use this to set up your VPN profile)"
  echo "2 : NordVPN Info Menu (Displays Available Cities, Countries etc)"
  echo "x : Exit the menu"
  read -p "Enter the option number: " menu_option
  case $menu_option in
    1)
        # VPN Setup SubMenu
        nord_vpn_setup_submenu
        ;;
    2)
        # Move to VPN Details menu
        nord_vpn_details_menu
        ;;
    [xX])
        # Exit the menu
        clear
        echo "Exiting the menu"
        exit 0
        ;;
    *)
      clear
      echo "Invalid option. Please select a valid option."
      continue_button
      ;;
  esac
}

# ---------------------------------------------------------------------------- #
#                               VPN Setup SubMenu                              #
# ---------------------------------------------------------------------------- #

nord_vpn_setup_submenu() {
  clear
  echo "VPN Setup Submenu:"
  echo "1 : Pick Random VPN Server based on Country"
  echo "2 : Pick Random VPN Server based on City"
  echo "3 : Populate Nord Credentials."
  echo "4 : Modify OpenVPN Credentials (Nord Credentials) file."
  echo "5 : Instructions to manually set up VPN and select server."
  echo "6 : Reset OpenVPN Configuration back to default."
  echo "b : Go back to the main menu"
  echo "c : Go to VPN Details Menu to display options"
  echo "x : Exit the menu"
  
  read -p "Enter the option number: " nord_vpn_setup_submenu_option

  case $nord_vpn_setup_submenu_option in
    1)
        # Initial Setup
        clear
        generate_credentials
        select_country_code_random_server
        post_setup_instructons
        continue_button
        ;;
    2)
        # Pick City
        clear
        generate_credentials
        select_server_by_city
        post_setup_instructons
        continue_button
        ;;
    3)
        # Setup Credentials File
        clear
        generate_credentials
        ;;
    4)
        # Reset Credentials File
        clear
        reset_credentials
        ;;
    5)
        # Provide instructions on how to set up a specific VPN server endpoint.
        clear
        manual_server_setup_instructions
        post_setup_instructons
        continue_button
        ;;
    6)
        # Remove OpenVPN Customizations
        clear
        reset_openvpn_config
        continue_button
        ;;
    [bB])
        # Main Menu
        vpn_setup_menu
        ;;
    [cC])
        # Move to VPN Details menu
        nord_vpn_details_menu
        ;;
    [xX])
        # Exit the menu
        clear
        echo "Exiting the menu"
        exit 0
        ;;
    *)
        echo "Invalid option. Please select a valid option."
        continue_button
        ;;
  esac

  # Call the submenu again to allow further selection
  nord_vpn_setup_submenu
}

# ---------------------------------------------------------------------------- #
#                              Nord Query Submenu                              #
# ---------------------------------------------------------------------------- #

nord_vpn_details_menu() {
  clear
  echo "Nord VPN Details Menu:"
  echo "1: Show all Country Codes."
  echo "2: Show all available cities."
  echo "3: Show available cities by Country."
  echo "4: Show available servers by city."
  echo "5: Show server count by country."
  echo "b: Go back to the main menu"
  echo "c: Go to VPN Setup Menu to manage your VPN profile"
  echo "x: Exit"
  read -p "Enter the option number: " nord_vpn_details_submenu_option

  case $nord_vpn_details_submenu_option in
    1)
        # Show Country Codes
        print_country_code
        continue_button
        ;;
    2)
        # Show All Cities
        echo "Country - City"
        show_all_available_cities
        continue_button
        ;;
    3)
        # Show City by Country Code
        show_available_cities_by_country
        continue_button
        ;;
    4)
        # Show Servers by Country
        show_available_servers_by_city
        continue_button
        ;;
    5)
        # Show Server Count by Country
        print_server_count_by_country
        continue_button
        ;;
    [bB])
        # Main Menu
        vpn_setup_menu
        ;;
    [cC])
        # VPN Setup SubMenu
        nord_vpn_setup_submenu
        ;;
    [xX])
        # Exit the menu
        echo "Exiting the menu"
        clear
        exit 0
        ;;
    *)
        echo "Invalid option. Please select a valid option."
        ;;
  esac
  # Call the submenu again to allow further selection
  nord_vpn_details_menu
}

# ---------------------------------------------------------------------------- #
#                                     Code                                     #
# ---------------------------------------------------------------------------- #

generate_credentials(){
# Check if credentials file exists
if [[ -f "$credentials_file" ]]; then
  echo "Credentials file already exists: $credentials_file. Skipping prompt!"
else
  # Prompt for OpenVPN credentials
  read -p "Enter your OpenVPN username: " username
  read -s -p "Enter your OpenVPN password: " password
  echo

  # Save credentials to the file
  echo -e "$username\n$password" > "$credentials_file"
  echo "Credentials saved to $credentials_file"
fi
}

reset_credentials(){
# Check if credentials file exists
if [[ -f "$credentials_file" ]]; then
  echo "Credentials file found. Clearing contents"
  read -p "Enter your OpenVPN username: " username
  read -s -p "Enter your OpenVPN password: " password
  echo

  # Save credentials to the file
  echo -e "$username\n$password" > "$credentials_file"
  echo "Credentials saved to $credentials_file"
else
  # Prompt for OpenVPN credentials
  read -p "Enter your OpenVPN username: " username
  read -s -p "Enter your OpenVPN password: " password
  echo

  # Save credentials to the file
  echo -e "$username\n$password" > "$credentials_file"
  echo "Credentials saved to $credentials_file"
fi
}

print_server_count_by_country(){
  curl --silent "https://api.nordvpn.com/v1/servers?limit=16384" | jq --raw-output '. as $parent | [.[].locations[].country.name] | sort | unique | .[] as $country | ($parent | map(select(.locations[].country.name == $country)) | length) as $count |  [$country, $count] |  "\(.[0]): \(.[1])"'
}

print_country_code(){
  # Make API request to retrieve country codes and names
  response=$(curl -s https://api.nordvpn.com/v1/servers/countries)

  # Check if the response is valid JSON
  if ! jq -e . >/dev/null 2>&1 <<<"$response"; then
    echo "Error: Failed to parse the API response as valid JSON."
    exit 1
  fi

  # Parse the response to extract the country codes and names
  country_data=$(echo "$response" | jq -r '.[] | "\(.code) : \(.name) : \(.id)"')

  # Print the country codes and names
  echo "Server Code : Country : Server ID"
  echo "$country_data"
}

manual_server_setup_instructions(){
  # Provide instructions on how to set up a specific VPN server endpoint.
  echo "To pick a specific VPN server, open a new terminal window :"
  echo "To get a list of servers, paste the following into the terminal;"
  read -p "Enter the first two characters.. It's case sensitive! : " input
  echo "cd "$ovpn_tcp_directory" && ls | grep -E "^$input""
  echo "Select a server of your choosing.. For example, IE83.nordvpn.com.tcp.ovpn"
  echo "Move the file and rename it exactly as shown here.."
  echo "cp "$ovpn_tcp_directory" "$profile_location"/openvpn.conf "
  echo "This will ensure that autostart is enabled on the newly created openvpn.conf file"
  echo

  # Check if Enter was pressed (newline character)
  if [[ $REPLY == "" ]]; then
    echo "Continuing..."
  else
    # Check if Esc was pressed
    if [[ $REPLY == $'\e' ]]; then
      echo "Exiting..."
      exit 0
    fi
  fi
}

display_country_codes() {
  echo "Available country codes:"
  echo "$1"
}

select_country_code_random_server(){
  # Print the country codes
  country_data=$(print_country_code)
  display_country_codes "$country_data"

  # Prompt for Country Code
  read -p "Enter the desired country code (e.g., US, GB, VN etc): " country_code

  # Validate the country code
  valid_codes=$(echo "$country_data" | awk '{print $1}')
  while ! grep -qw "$country_code" <<<"$valid_codes"; do
    echo "Invalid country code. Please try again."
    read -p "Enter the desired country code (e.g., US, GB, VN etc): " country_code
  done

  # Further processing with the validated country code
  echo "Selected country code: $country_code"

  # Convert the country code to uppercase
  country_code=$(echo "$country_code" | awk '{print toupper($0)}')

  # Retrieve the country ID based on the selected country code
  country_id=$(echo "$country_data" | awk -v code="$country_code" -F ':' '$1 ~ code { print $3 }' | awk '{$1=$1};1')

  # Retrieve the recommended server hostname which will correspond with an OpenVPN File
  server_id=$(curl --silent "https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]="$country_id"&limit=3" | jq --raw-output '.[].hostname')
  select_openvpn_server_profile
}

# Choose one of the VPN profiles gathered. Ensure that the server ID exists in the openVPN config files
# Move it over to /etc/openvpn to be referenced as the default openvpn profile
select_openvpn_server_profile() {
  # Flag to track if a match is found
  match_found=false

  # Iterate over the server IDs
  for id in $server_id; do
    # Create the filename pattern
    filename_pattern="${id}.tcp.ovpn"

    # Search for a matching filename within the folder
    matched_filename=$(find "$ovpn_tcp_directory" -name "$filename_pattern" -print -quit)

    # Check if a match was found
    if [ -n "$matched_filename" ]; then
      # Identify Match
      echo "Match found: $matched_filename"
      # Save matched filename as a variable
      chosen_server_id=$(basename "$matched_filename" ".nordvpn.com.tcp.ovpn")
      # Set switch to true
      match_found=true

      # Move the matched file to users desktop for persistent profiles to retain it.
      mv "$matched_filename" "$profile_location/openvpn.conf"

      break  # Exit the loop after the first match
    fi
  done

  # Check if no match was found
  if [ "$match_found" != true ]; then
    echo "No match found."
  fi
}

reset_openvpn_config(){
  # Stop OpenVPN Service
  service openvpn stop
  # Remove OpenVPN Config
  rm -rf $credentials_file
  rm -rf $profile_location
  # Start Servive
  service openvpn start
  echo "To set up your VPN Credentials again;"
  echo "Please go to first time setup menu option"
  echo "Or follow the manual instructions"
}

continue_button() {
  read -n 1 -s -r -p "Press Enter to continue or Esc to exit..."
  echo

  if [[ $REPLY == "" ]]; then
    echo "Continuing..."
  elif [[ $REPLY == $'\e' ]]; then
    echo "Exiting..."
    exit 0
  else
    echo "Invalid input. Continuing..."
  fi
}

get_country_id(){
  # Print the country codes
  country_data=$(print_country_code)
  display_country_codes "$country_data"

  # Prompt for Country Code
  read -p "Enter the desired country code (e.g., US, GB, VN etc): " country_code

  # Validate the country code
  valid_codes=$(echo "$country_data" | awk '{print $1}')
  while ! grep -qw "$country_code" <<<"$valid_codes"; do
    echo "Invalid country code. Please try again."
    read -p "Enter the desired country code (e.g., US, GB, VN etc): " country_code
  done

  # Further processing with the validated country code
  echo "Selected country code: $country_code"

  # Convert the country code to uppercase
  country_code=$(echo "$country_code" | awk '{print toupper($0)}')

  # Retrieve the country ID based on the selected country code
  country_id=$(echo "$country_data" | awk -v code="$country_code" -F ':' '$1 ~ code { print $3 }' | awk '{$1=$1};1')

  # Export the country ID as an environment variable
  export country_id="$country_id"
  clear
}

show_available_cities_by_country(){
    get_country_id
    echo "Available Cities:"
    curl --silent "https://api.nordvpn.com/v1/servers/countries?filters\[country_id\]="$country_id"&limit=20" | jq --raw-output '.[] | . as $parent | .cities[] | [$parent.name, .name, .id] | "\(.[0]) - \(.[1]) "'
}

show_all_available_cities(){
  curl --silent "https://api.nordvpn.com/v1/servers/countries" | jq --raw-output '.[] | . as $parent | .cities[] | [$parent.name, $parent.id, .name, .id] | "\(.[0]) - \(.[2])"'
}

select_server_by_city(){
  show_all_available_cities
  read -p "Enter the City Name (e.g., Atlanta, Manchester, Dubai etc): " city_name

  hostname_limit=5

  # Retrieve server data
  server_data=$(curl -s "https://api.nordvpn.com/v1/servers?limit=99999")

  # Filter servers by city
  filtered_servers=$(echo "$server_data" | jq -r --arg city "$city_name" '.[] | select(.locations[].country.city.name == $city)')

  # Extract up to 5 hostnames from filtered servers
  hostnames=$(echo "$filtered_servers" | jq -r '.hostname' | head -n $hostname_limit)

  # Print the filtered hostnames
  echo "Recommended servers for $city_name:"
  while IFS= read -r hostname; do
    echo "$hostname"
  done <<< "$hostnames"
  
  # Flag to track if a match is found
  match_found=false
  
  # Iterate over the server IDs
  for id in $hostnames; do
    # Create the filename pattern
    filename_pattern="${id}.tcp.ovpn"

    # Search for a matching filename within the folder
    matched_filename=$(find "$ovpn_tcp_directory" -name "$filename_pattern" -print -quit)

    # Check if a match was found
    if [ -n "$matched_filename" ]; then
      # Identify Match
      echo "Match found: $matched_filename"
      # Save matched filename as a variable
      chosen_server_id=$(basename "$matched_filename" ".nordvpn.com.tcp.ovpn")
      # Set switch to true
      match_found=true

      # Move the matched file to users desktop for persistent profiles to retain it.
      mv "$matched_filename" "$profile_location/openvpn.conf"

      break  # Exit the loop after the first match
    fi
    done

    # Check if no match was found
    if [ "$match_found" != true ]; then
      echo "No match found."
    fi
}

show_available_servers_by_city(){
  
  show_all_available_cities
  read -p "Enter the City Name (e.g., Atlanta, Manchester, Dubai etc): " city_name

  hostname_limit=5
  # Retrieve server data
  server_data=$(curl -s "https://api.nordvpn.com/v1/servers?limit=99999")

  # Filter servers by city
  filtered_servers=$(echo "$server_data" | jq -r --arg city "$city_name" '.[] | select(.locations[].country.city.name == $city)')

  # Extract up to 5 hostnames from filtered servers
  hostnames=$(echo "$filtered_servers" | jq -r '.hostname' | head -n $hostname_limit)

  # Print the filtered hostnames
  echo "Recommended servers for $city_name:"
  while IFS= read -r hostname; do
    echo "$hostname"
  done <<< "$hostnames"
}

post_setup_instructons(){
  echo "Providing there were no errors, this is now complete!"
  echo "You can test and validate this immediately by typing the following command;"
  echo "openvpn --config ~/openvpn/openvpn.conf"
  echo "and then visiting a website like https://ipleak.net to verify"
  echo "Note the above openvpn command takes over the terminal window &.."
  echo "terminates connection when the terminal window is closed or cancelled."
  echo "On the next boot of your Kasm, it will automatically start up in the background"
}

# ---------------------------------------------------------------------------- #
#                                  Run Command                                 #
# ---------------------------------------------------------------------------- #
while true; do
  vpn_setup_menu
done
