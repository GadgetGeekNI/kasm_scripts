# App Install
curl -L -o google-earth-pro.deb https://dl.google.com/dl/earth/client/current/google-earth-stable_current_amd64.deb 
apt-get update 
apt-get install -y --no-install-recommends apt-utils 
apt-get -y install xdg-utils 
apt-get install -y ./google-earth-pro.deb 
rm -rf ./google-earth-pro.deb 

# Desktop Icon
cp /usr/share/applications/google-earth-pro.desktop $HOME/Desktop/ 
chmod +x $HOME/Desktop/google-earth-pro.desktop 
chown 1000:1000 $HOME/Desktop/google-earth-pro.desktop
