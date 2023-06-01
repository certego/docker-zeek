#!/bin/sh

printf "#############################################################\n"
printf "Deploying config with zeekctl...\n"
printf "#############################################################\n\n"

zeekctl deploy

printf "\n#############################################################\n"
printf "Deploy done!\n"
printf "#############################################################\n\n"

# lanuch cron daemon for `zeekctl cron`
printf "#############################################################\n"
printf "Running cron in background\n"
printf "#############################################################\n\n"
cron &

printf "#############################################################\n"
printf "Attaching stdout to '/var/log/zeek/spool/stats.log'...\n"
printf "#############################################################\n\n"
touch /var/log/zeek/spool/stats.log
tail -f /var/log/zeek/spool/stats.log