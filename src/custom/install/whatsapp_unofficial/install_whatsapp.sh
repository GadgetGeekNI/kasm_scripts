# App Install
cd /tmp
curl -L -o whatsapp-desktop.deb https://github.com/oOthkOo/whatsapp-desktop/releases/download/v0.5.2/whatsapp-desktop-x64.deb
apt-get update
apt-get install -y ./whatsapp-desktop.deb

sed -i 's,/opt/whatsapp-desktop/WhatsApp,/opt/whatsapp-desktop/WhatsApp --no-sandbox,g' /usr/share/applications/whatsapp.desktop

# Desktop Icon
cp /usr/share/applications/whatsapp.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/whatsapp.desktop
chown 1000:1000 $HOME/Desktop/whatsapp.desktop