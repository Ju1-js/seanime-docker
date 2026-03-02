#!/bin/sh
if [ -f /tmp/is_https ]; then
    wget -q -t 1 --spider --no-check-certificate https://127.0.0.1:43211 || (rm -f /tmp/is_https && exit 1)
else
    wget -q -t 1 --spider http://127.0.0.1:43211 || \
    (wget -q -t 1 --spider --no-check-certificate https://127.0.0.1:43211 && touch /tmp/is_https) || \
    exit 1
fi