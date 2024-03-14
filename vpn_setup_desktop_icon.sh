#!/bin/bash

# Create a Desktop Icon and launch the VPN setup Menu without having to execute 
# it within a terminal window.

desktop_path="$HOME/Desktop"
script_path="/usr/bin/scripts/openvpn/vpn_setup.sh"  # Replace with your script's name

launcher_path="$desktop_path/VPN Setup.desktop"  # Customize the launcher name if desired

launcher_contents="[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=xfce4-terminal --hide-borders --hide-menubar --zoom=-1 --hide-scrollbar -x $script_path
Name=VPN Setup Menu
Comment=This will open the VPN Setup Menu
Icon=utilities-terminal
"

echo "$launcher_contents" > "$launcher_path"
chmod +x "$launcher_path"
