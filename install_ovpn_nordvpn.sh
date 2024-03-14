apt-get update
apt-get install -y openvpn jq
cd /etc/openvpn
wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
unzip -q ovpn.zip
rm ovpn.zip

profile_location="/home/kasm-user/openvpn"

mkdir -p $profile_location

# Set Credentials File
credentials_file="$profile_location/auto-auth.txt"

# Define the directories to search for .ovpn files
ovpn_directories=("/etc/openvpn/ovpn_tcp" "/etc/openvpn/ovpn_udp")

# Initialize a counter for modified files
modified_files_count=0

# Find and replace 'auth-user-pass' directive in each .ovpn file
for directory in "${ovpn_directories[@]}"; do
  # Check if the directory exists
  if [[ -d "$directory" ]]; then
    # Loop through .ovpn files in the directory
    for file in "$directory"/*.ovpn; do
      # Check if any .ovpn files exist
      if [ -e "$file" ]; then
        # Check if the line already exists in the file
        if ! grep -qFx "auth-user-pass $credentials_file" "$file"; then
          # Remove existing 'auth-user-pass' lines from the file
          sed -i '/auth-user-pass/d' "$file"
          
          # Add the 'auth-user-pass' line with the credentials file location
          echo "auth-user-pass $credentials_file" >> "$file"
          
          ((modified_files_count++))
        fi
      fi
    done
  else
    echo "Directory $directory does not exist."
  fi
done

# Print the count of modified files
echo "$modified_files_count files modified"
