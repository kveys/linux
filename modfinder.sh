#!/bin/bash
#######################################################################################
# auteur: kve                                                                         #
# datum:  02/12/2014                                                                  #
#                                                                                     #
# Aantekeningen:                                                                      #
# Dit script wordt gebruikt om de laatste wijzigingsdatum van bestanden op te sporen. #
#                                                                                     #
# 28/09/2015: optie -t  en MAIL toegevoegd                                            #
# 02/12/2014: opties -u en -g toegevoegd                                              #
# 07/02/2014: script herwerkt met opties -post                                        #
# 25/11/2013: eerste versie                                                           #
#######################################################################################

OUTF=/tmp/modfinder.log
POST=/shares/postkantoor
MAIL=0

swaks=/usr/local/bin/swaks
mailfrom=security@schaubroeck.be
mailto=kve@schaubroeck.be
mailsrv=mail2

clear

if [ "$#" -lt 1 ];then
        echo "Geen geldige optie gevonden. EXIT."
        echo "Gebruik : modfinder <pad> -post -u(ser) -g(roup) -t(ijd_in_minuten)"
        echo "Parameters zijn (nog) NIET combineerbaar"
        exit 1
fi

echo "Zoek naar laaste wijziginsdatum van bestanden in $1"  | tee $OUTF
echo "Het resultaat schrijven we weg naar $OUTF" | tee -a $OUTF
echo ""


if [ "$1" == "-post" ];then
        find $POST -type f -iname '*.pst' -printf %Td/%Tm/%TY-%TH:%TM\\t%P\\t%u\\t%m\\n| sort --key=1.7,1.10 --key=1.4,1.5 -n --key=1.1,1.2 -n| tee -a $OUTF
elif [ "$2" == "-u" ];then
        find $1 -type f -printf %Td/%Tm/%TY-%TH:%TM\\t%P\ \[u:%u\]\\n| sort --key=1.7,1.10 --key=1.4,1.5 -n --key=1.1,1.2 -n| tee -a $OUTF
elif [ "$2" == "-g" ];then
        find $1 -type f -printf %Td/%Tm/%TY-%TH:%TM\\t%P\ \[g:%g\]\\n| sort --key=1.7,1.10 --key=1.4,1.5 -n --key=1.1,1.2 -n| tee -a $OUTF
elif [ "$2" == "-t" ];then
        find $1 -type f -mmin -$3 -printf %Td/%Tm/%TY-%TH:%TM\\t%P\ \[g:%g\]\\n| sort --key=1.7,1.10 --key=1.4,1.5 -n --key=1.1,1.2 -n| tee -a $OUTF
else

        find $1 -type f -printf %Td/%Tm/%TY-%TH:%TM\\t%P\\n| sort --key=1.7,1.10 --key=1.4,1.5 -n --key=1.1,1.2 -n| tee -a $OUTF
fi

# Mail resultaat naar @mailto.

if [ "$MAIL" == 1 ];then
        cat $OUTF | $swaks --h-Subject "[FILECHANGES] `hostname`: $1 " --body - -t $mailto -server $mailsrv -from $mailfrom 2>&1 > /dev/null
fi
