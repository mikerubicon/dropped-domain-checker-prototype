##
# Uniwersalne narzedzia srodowiska bash

print() {
    ##
    # Wypisuje komunikaty gdy skrypt w trybie DEBUG
    if [ "$DEBUG" == "1" ]
	then
	    /bin/echo -ne "$1";
        else
            return 0;
    fi
}

log() {
    ##
    # Zapisuje komunikaty do loga
    if [ "$LOGON" == "1" ]
	then
	    print "[ Wpis do loga: $1 >> $LOG_FILE ]\n"
	    print "$1" >>$LOG_FILE;
	else
	    print "[ Logowanie jest wylaczone! ]\n"
        return 0;
    fi
}

get_stamp() {
    ##
    # pobiera biezacy znak daty - czasu
    # - : domyslnie wypisuje wersje ze spacjami do czytania

    CUR_TIME=`date +%H-%M-%S`
    CUR_TIME_HR=`/bin/date +%T`
    CUR_DATE=`date +%Y-%m-%d`
    CUR_DATE_HR=`/bin/date +%Y.%m.%d`

    STAMP="${CUR_DATE}_${CUR_TIME}";
    STAMP_HR="${CUR_DATE_HR} ${CUR_TIME_HR}";

    case "$1" in
	"time") 	/bin/echo -ne ${CUR_TIME};;
	"time_hr") 	/bin/echo -ne ${CUR_TIME_HR};;
	"date") 	/bin/echo -ne ${CUR_DATE};;
	"date_hr") 	/bin/echo -ne ${CUR_DATE_HR};;
	"datetime") 	/bin/echo -ne ${STAMP};;
	"datetime_hr") 	/bin/echo -ne ${STAMP_HR};;
	*) echo -ne ${STAMP_HR}
    esac

    return $?;
}
