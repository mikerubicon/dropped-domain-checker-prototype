#!/usr/bin/env perl

##
# Pobiera surowe wyniki wyszukiwania nazw domen we WHOIS

use strict;
use warnings;
use utf8;
use Net::Whois::Raw qw( whois );
use Net::SMTP;
use Data::Dumper;

## Zmienne globalne
#my $arg = shift @ARGV;
#my $domain_name = $arg ? $arg : '';
my $domain_name = 'prestagear.com';

## Zmienne powiadomien email
my $notificationFrom = 'perl@__SERVER_DOMAIN_NAME__';
my @notificationTo = ( '' ); ### admin email
my $smtpHost = '127.0.0.1';
my $statusTitle = '';
my $statusBody = '';

## Zmienne danych domeny
my $whois_data = '';
my $registrar_name = '';
my $registrar_type = '';
my $creation_date = '';
my $creation_date_last = '2013.08.13';
my $creation_time = '';
my $creation_time_last = '14:20:30';
my $last_modification_date = '';
my $last_modification_date_last = '2013.08.13';
my $last_modification_time = '';
my $last_modification_time_last = '14:20:30';
my $expiration_date = ''; # renewal
my $expiration_date_last = '2014.08.13';
my $expiration_time = '';
my $expiration_time_last = '14:20:30';
my $domain_is_free = 0;
my $domain_in_whois = 0;

## Zmienne logowania i czasu
my $fileLog = 'logs/lastrun-test.txt';
my $timestamp = timestamp();
my ($date, $time) = $timestamp =~ /(\d+\.\d+\.\d+)_(\d+\:\d+\:\d+)/;

## Warunkowe odptytanie o domene
if ( $domain_name ne '' ) {
    my $message = " [ i| Sprawdzam WHOIS domeny: $domain_name ]\n";
    print $message;
    string_to_file($timestamp . $message, $fileLog);
    
    ## Zapytanie do WHOIS
    $whois_data = whois($domain_name);
    
} else {
    print "[ !| Brak nazwy domeny! ]\n";
    die();
}

if ( $whois_data =~ /No match for domain/ || $whois_data =~ /No information available about domain name/ ) {
    my $message = "[ !| Brak danych domeny we WHOIS ]\n";
    print $message;
    string_to_file($timestamp . $message, $fileLog);
    $domain_in_whois = 0;
    $domain_is_free = 1;
    
} else {
    ## Pobranie danych z wynikow WHOIS
    $domain_in_whois = 1;
    $domain_is_free = 0;
    
    # Typ registrara
    if ( $whois_data =~ /registrant type:\s+(\w+)/ ) {
        $registrar_type = unspace($1);
    }
    
    # Data i czas utworzenia
    if ( $whois_data =~ /created:\s+ (\d+\.\d+\.\d+)\s+(\d+\:\d+\:\d+)/ ) {
        $creation_date = $1;
        $creation_time = $2;
    }
    
    # Data i czas ostatniej modyfikacji
    if ( $whois_data =~ /last modified:\s+ (\d+\.\d+\.\d+)\s+(\d+\:\d+\:\d+)/ ) {
        $last_modification_date = $1;
        $last_modification_time = $2;
    }
    
    # Data odnowienia (wygasania)
    if ( $whois_data =~ /renewal date:\s+ (\d+\.\d+\.\d+)\s+(\d+\:\d+\:\d+)/ ) {
        $expiration_date = $1;
        $expiration_time = $2;
    }
}

## Podsumowanie sprawdzenia - domena wolna
if ( $domain_is_free == 1 && $domain_in_whois == 0 ) {
    my $message = "[ Domena ($domain_name) jest wolna do rejestracji! ]\n";
    print $message;
    string_to_file($timestamp . $message, $fileLog);
    
    ## Wyslij e-mail
    $statusTitle = ' Monitoring whois dla domeny: ' . $domain_name;
    $statusBody = "Witaj!\n\n $message \n";
    foreach my $recipient ( @notificationTo ) {
        print "[Wysylam -> $recipient]\n";
        mailNotification( $recipient, $notificationFrom, $statusTitle, $statusBody );
    }
}

if ( $domain_in_whois == 1 && $domain_is_free == 0 ) {
    my $message = "[ Domena ($domain_name) jest zajeta]\n";
    print $message;
    string_to_file($timestamp . $message, $fileLog);
    
    ## Sprawdzenie pol domeny - czas wygasania
    if ( $expiration_date ne $expiration_date_last ) {
        my $message = "[ Zmienila sie data wygasania domeny /renewal date:/ ($domain_name) z /$expiration_date_last/ na /$expiration_date/, prawdopodobnie domena zostala przedluzona na kolejny okres. ]\n";
        print $message;
        string_to_file($timestamp . $message, $fileLog);
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
	$timestamp = $year .'.'. $month .'.'. $day .'_'. $hr .':'. $min .':'. $sec;
	
	return $timestamp;
}

sub unspace {
	##
	# usuwa spacje ?
	my @stringer = @_ ? @_ : $_;
    $_ = join( ' ', split(' ')) for @stringer;
    return wantarray ? @stringer : "@stringer";
}