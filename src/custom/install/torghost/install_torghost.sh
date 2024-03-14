apt-get update
apt-get -y install python3-distutils python3-apt python3-packaging tor cython3
cd /tmp && git clone https://github.com/SusmithKrishnan/torghost.git && chmod +x torghost/build.sh
cd torghost && ./build.sh
