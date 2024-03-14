curl -L -o express-vpn.deb https://www.expressvpn.works/clients/linux/expressvpn_3.50.0.11-1_amd64.deb
sudo apt-get update
sudo apt-get install -y ./express-vpn.deb
rm -rf ./express-vpn.deb
service expressvpn restart