#!/bin/sh
zeekctl deploy
# lanuch cron daemon for `broctl cron`
cron

touch /var/log/zeek/spool/stats.log
tail -f /var/log/zeek/spool/stats.log
