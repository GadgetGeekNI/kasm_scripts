#!/usr/bin/env bash
# Install ChromeDriver.
wget -N https://chromedriver.storage.googleapis.com/113.0.5672.63/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 0755 /usr/local/bin/chromedriver

# Install Selenium
pip install selenium

