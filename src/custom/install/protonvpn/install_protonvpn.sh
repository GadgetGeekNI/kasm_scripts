# Doesn't work with Kasm. Here as a reference and for future testing.
wget -O protonvpn.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3_all.deb
apt-get install -y ./protonvpn.deb
apt-get update
apt-get install -y protonvpn-cli