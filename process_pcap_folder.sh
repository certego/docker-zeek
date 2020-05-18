#!/bin/sh
for i in `ls ${1}/*.pcap`;
do
    echo "Processing pcap ${i}"
    zeek -C -r ${i} ${2} "${3}"
done
