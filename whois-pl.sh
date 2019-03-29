#!/usr/bin/env bash

DEBUG=1
LOGON=1

ROOT_DIR='/var/www/html/sandbox/domaincheck'

. src/tools.sh
. src/domain-monitor-lib.sh

## Ustawienia
LOG_FILE="${ROOT_DIR}/logs/whois-pl-log.txt"
DOMAINS=(wolnastronawwwktorejniema.pl)

# CZAS | DATA - startowa dla nazw plikow
TIME=$(get_stamp time)
TIME_HR=$(get_stamp time_hr)
DATE=$(get_stamp date)
DATE_HR=$(get_stamp date_hr)
TIMESTAMP=$(get_stamp datetime)
TIMESTAMP_HR=$(get_stamp datetime_hr)


## Akcja
print "[ $(get_stamp) | -START- ]\n"

domain_check "${DOMAINS[@]}";

print "[ $(get_stamp) | -STOP- ]\n"
## Koniec