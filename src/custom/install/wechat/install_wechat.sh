apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        locales \
        locales-all \
        gnupg \
        locales \
        locales-all \
        fcitx-libs-dev \
        fcitx-bin \
        fcitx-googlepinyin \
        fcitx \
        fcitx-ui-qimpanel \
        fcitx-sunpinyin \
        dbus-x11 \
        im-config
apt-get clean

echo "deb http://archive.ubuntukylin.com/ubuntukylin focal-partner main" > /etc/apt/sources.list.d/wechat.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56583E647FFA7DE7

apt-get update && apt-get install -y --no-install-recommends \
        weixin \
        language-pack-zh* \
        chinese* \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        xfonts-wqy


cp /usr/share/applications/weixin.desktop $HOME/Desktop/ 
chmod +x $HOME/Desktop/weixin.desktop 
chown 1000:1000 $HOME/Desktop/weixin.desktop
