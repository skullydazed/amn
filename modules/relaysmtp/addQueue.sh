#!/bin/sh
# This script takes a message from STDIN and adds it to the irc message queue

QUEUE=$HOME/.amn/relaysmtp.q
MESSAGE=''
INBODY=0
while read LINE; do
	if echo $LINE | grep -q '^To: '; then
		PASSWORD=$(echo $LINE | cut -f 1 -d @ | cut -f 2 -d -)
		DESTNICK=$(echo $LINE | cut -f 1 -d @ | cut -f 3 -d -)
	elif [ "$LINE" = "" ]; then
		INBODY=1
	elif [ "$INBODY" = "1" ]; then
		MESSAGE="${MESSAGE}${LINE} "
	fi
done

if ! printf '%s\n' "$PASSWORD $DESTNICK $MESSAGE" >> "$QUEUE"; then
	printf 'RelaySMTP could not append to %s\n' "$QUEUE" >&2
	exit 1
fi
