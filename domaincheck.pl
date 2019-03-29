#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode;
use Net::WhoisNG;
use Net::SMTP;
use Data::Dumper;

##
# Sprawdza na podstawie WHOIS, dostepnosc domen globalnych,
# wysyla powiadomienia gdy domena jest wolna lub gdy
# zmienily sie daty wygasania oraz ostatniej aktualizacji.

# Okresy wygasania domen globalnych (net, com, org, etc ...)
# Dzien 0 - Domain name is not renewed (expires)
# Dzien 1 - 40 Domain Name Grace period
# Dzien 40 - 45 Domain Name Pending Delete period
# Dzien 46 - Domain Name Purged from Registry and becomes available

my $arg = shift @ARGV;
my $domain_name = $arg ? $arg : '';
if ( $domain_name !~ /(\.net|\.com|\.biz|\.info)/) {
    ## Tylko domeny globalne!
    die("[ ! | Skrypt obsluguje tylko domeny globalne! ]\n");
}

## Zmienne powiadomien email
my $notificationFrom = 'perl@__SERVER_DOMAIN_NAME__';
my @notificationTo = ( '' ); ## admin e-mails
my $smtpHost = '127.0.0.1';
my $statusTitle = '';
my $statusBody = '';

## Zmienne danych domeny
my $data = '';
my $no_match_name = '';
my $registrar_name = '';
my $last_updated_date = '';
my $last_updated = '';
my $expiration_date = '';
my $expiration = '';
my $creation_date = '';
my $free = 0;

## Zmienne logowania
my $fileLog = './logs/lastrun.txt'; ## TODO ADD ROOT PATH?
my $timestamp = timestamp();

if ($domain_name ne '') {
    my $string = " [ i| Sprawdzam WHOIS domeny: $domain_name ]\n";
    print $string;
    string_to_file($timestamp . $string, $fileLog);
} else {
    print "[ !| Brak nazwy domeny! ]\n";
    die();
}

## Utworzenie obiektu danych whois dla domeny
my $w = new Net::WhoisNG( $domain_name );
    $w->lookUp();
 
## Dane domeny, prosto z obiektu (brak dobrej metody)
$data = $w->{'rslts'};

foreach my $line ( @{$data} ) {
    print "[ Linia: $line ]\n";
    
    ## Wykrycie kodowania znakow
    #if ( utf8::is_utf8($data) ) {
    #    print " +++++++ is utf8\n";
    #    string_to_file(" +++++++ is utf8\n", $fileLog);
    #} else {
    #    string_to_file(" ------- is not utf8\n", $fileLog);
    #    print " ------- is not utf8\n";
    #}
    
    ## Kodowanie do perl-utf8
    $line = decode('ascii', $line);
    print "[ Linia zdekodowana: $line ]\n";
    
    ## Sprawdzenie czy whois zna domene
    if ( $line =~ /No match for \"(.+)\"\./) {
        $free = 1;
        $no_match_name = $1;
        print "[ Taka domena nie istnieje: $no_match_name]\n";
    }
    
    ## Pobranie pol domeny z WHOIS    
    if ( $line =~ /Registrar of Record: (.+)\./) {
        $registrar_name = $1;
        print "[ Nazwa registrara: $registrar_name ]\n";
    }
    if ( $line =~ /Record last updated on (.+)\./) {
        $last_updated_date = $1;
        print "[ Ostatnia aktualizacja: $last_updated_date ]\n";
    }
    if ( $line =~ /Record expires on (.+)\./) {
        $expiration_date = $1;
        print "[ Data wygasniecia: $expiration_date ]\n";
    }
    if ( $line =~ /Record created on (.+)\./) {
        $creation_date = $1;
        print "[ Data utworzenia: $creation_date ]\n";
    }
}

## Domena wolna - wyslij mailem powiadomienie
if ( $free == 1 ) {
    $statusTitle = ' Monitoring whois dla domeny: ' . $domain_name;
    $statusBody = "Witaj!\n\n Domena $domain_name jest wolna w whois!\n\n";
    string_to_file($timestamp . $statusTitle . $statusBody, $fileLog);
    
    foreach my $recipient ( @notificationTo ) {
        print "[Wysylam -> $recipient]\n";
        mailNotification( $recipient, $notificationFrom, $statusTitle, $statusBody );
    }
} else {
    my $string = "[ $timestamp | Domena: $domain_name ZAJETA. \nNazwa registrara: $registrar_name, Ostatnia aktualizacja: $last_updated_date, Data wygasniecia: $expiration_date, Data utworzenia: $creation_date ]\n"; 
    string_to_file($string, $fileLog);
}

## Zmian danych WHOIS (update oraz expires) - wyslij mailem powiadomienie
if ( $last_updated ne $last_updated_date || $expiration ne $expiration_date ) {
    $statusTitle = ' Monitoring whois dla domeny: ' . $domain_name;
    $statusBody = "Witaj!\n\n Domena $domain_name została zmodyfikowana w whois! \n\n (LAST UPDATE bylo $last_updated jest $last_updated_date),\n\n (EXPIRATION DATE bylo $expiration jest $expiration_date) \n\n";
    string_to_file($timestamp . $statusTitle . $statusBody, $fileLog);
    
    foreach my $recipient ( @notificationTo ) {
        print "[Wysylam -> $recipient]\n";
        mailNotification( $recipient, $notificationFrom, $statusTitle, $statusBody );
    }
}

## Koniec przetwarzania
print "++++++++++++++++++++++++++++++++++++++++++++++ -KONIEC- \n";
string_to_file("++++++++++++++++++++++++++++++++++++++++++++++ -KONIEC- \n\n", $fileLog);

## Funkcje dodatkowe
sub mailNotification {
    ##
    # Wysyla powiadomienie e-mail
    my $mail = $_[0]; # odbiorca
    my $mailFrom = $_[1]; # nadawca
    my $subject = $_[2]; # temat (powinien zawierac komunikat diagnostyczny)
    my $message = $_[3]; # tresc
    my $retval = '0'; # status wykonania
    
    # Instancja mailera
    my $smtp = Net::SMTP->new( $smtpHost );
    $smtp->mail( $mailFrom );
    $smtp->to( $mail );

    $smtp->data();
    $smtp->datasend("To: ". $mail ."\n");
    $smtp->datasend("Subject: ". $subject ."\n");
    $smtp->datasend("User-Agent: Monit AT dev-napad.pl Daemon\n");
    $smtp->datasend("MIME-Version: 1.0 \nContent-Type: text/plain; charset=us-ascii\n");
    $smtp->datasend("\n");
    $smtp->datasend("\n". $message ."\n"); 
    $smtp->dataend();
    $retval = $smtp->quit;
    
    ## TODO Status wysyłki dla mailNotification();
    
    #$retval = "$mail | $subject | $message ]\n";
    #$retval = "[retval| $status_1 | $status_2 ]\n";
    #print "-> $retval\n";
    return $retval;
}

sub string_to_file {
    ##
    # Zapisuje ciag znakow do pliku
    my $string = ($_[0]) ? $_[0] : '';
    my $file = ($_[1]) ? $_[1] : '';
    
    my $fh = IO::File->new(">> $file");
    if (defined $fh) {
        print $fh $string;
        $fh->close;
    }
}

sub timestamp {
	##
	# Zwraca znacznik czasu
	my ($sec, $min, $hr, $day, $mon, $yr) = localtime;
	my $timestamp = '';
	
	my $year = 1900 + $yr;
	my $month = $mon + 1;
		$month = sprintf('%02d', $month); #dopisuje zero
	$timestamp = $year .'-'. $month .'-'. $day .'_'. $hr .'-'. $min .'-'. $sec;
	
	return $timestamp;
}