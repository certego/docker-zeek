#!/bin/bash

# accepts interface to be analyzed as parameter
cd /var/log/zeek/
zeek -i ${1}