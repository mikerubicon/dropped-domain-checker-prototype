##
# Narzedzia sprawdzania whois.pl


domain_check() {
    
    _DOMAINS=($@)
    
    
    log "\n\n[ ------------------------------------------------------------ ]\n\n"
    
    for DOMAIN in ${_DOMAINS[*]};
	do
	 print "[ Sprawdzam: ${DOMAIN} ]\n"
	 ##
	 WHOIS_RESULT=$(/usr/bin/whois --verbose ${DOMAIN});
	 RETVAL=$?;
	 
	if [ "$RETVAL" == "0" ]
	    then
		log "[ $(get_stamp) | Wynik zapytania WHOIS: ${WHOIS_RESULT} ]\n\n"
		print "[ $(get_stamp) | Wynik zapytania WHOIS: ${WHOIS_RESULT} ]\n"
	    else
		log "[ $(get_stamp) | !! | Wynik zapytania WHOIS nieprawidlowy: ${WHOIS_RESULT} ]\n\n"
		print "[ $(get_stamp) | !! | Wynik zapytania WHOIS nieprawidlowy: ${WHOIS_RESULT} ]\n"
	fi
	 
    done
}