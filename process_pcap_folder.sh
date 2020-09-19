#!/bin/sh
#moving to tmp directory
mkdir -p /tmp/zeek-files
cd /tmp/zeek-files
for i in `ls ${1}/*.pcap`;
do
    echo "Processing pcap ${i}"
    zeek -C -r ${i} ${2} "${3}"
    for zeek_output in `ls *.log`;
    # copying zeek output files so they will not be ereased when running multiple pcaps
    do
        cat ${zeek_output} >> /var/log/zeek/${zeek_output}
        rm ${zeek_output}
    done
done
