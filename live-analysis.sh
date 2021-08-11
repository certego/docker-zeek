#!/bin/bash
# accepts interface to be analyzed as first parameter 
# and the file containing packages to be installed as second parameter

# Installing Zeek Packages
zkg list | cut -d' ' -f1 > /tmp/packages.txt
comm -3 /tmp/packages.txt ${2}  2>/dev/null > /tmp/to-install.txt

while IFS= read -r line; do
  zkg install --force $line
done < /tmp/to-install.txt

# Analyzing traffic over interface
cd /var/log/zeek/
zeek -i ${1}