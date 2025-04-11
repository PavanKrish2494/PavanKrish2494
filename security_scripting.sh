#!/bin/bash

LOG_FILE="/var/log/app.log"
PATTERN="5[0-9]{2}"
WEBHOOK_URL="<Mention here Webhook URL> "

tail -Fn0 $LOG_FILE | \
while read line ; do
    echo "$line" | grep -E "$PATTERN" > /dev/null
    if [ $? = 0 ]; then
        curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\" 5xx Error detected: $line\"}" \
        $WEBHOOK_URL
    fi
done
