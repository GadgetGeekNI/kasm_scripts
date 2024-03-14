# WhatsDesk is a WhatsApp alternative client for Linux Desktop.

wget -O whatsdesk.deb https://zerkc.gitlab.io/whatsdesk/whatsdesk_0.3.9_amd64.deb
apt-get -y install ./whatsdesk.deb

apt-get update

cp /usr/share/applications/whatsdesk.desktop $HOME/Desktop/ 
chmod +x $HOME/Desktop/whatsdesk.desktop 
chown 1000:1000 $HOME/Desktop/whatsdesk.desktop
