#!/bin/bash

##########################################################################
# auteur: kve                                                            #
# datum: 25/04/2019                                                      # 
#                                                                        #
# Aantekeningen:                                                         #
#                                                                        # 
# Beschrijving:                                                          #
# dit script maakt en controleert inhoud van bestanden ahv sha1sum       #
#                                                                        # 
##########################################################################

# variabelen en/of functies definiëren

awk=/bin/awk
cut=/bin/cut
find=/bin/find
grep=/bin/grep
head=/usr/bin/head
nl=/usr/bin/nl
sha1sum=/usr/bin/sha1sum
sort=/bin/sort
swaks=/usr/local/bin/swaks
tail=/usr/bin/tail
tee=/usr/bin/tee
uniq=/usr/bin/uniq

MONMONDIR=/usr/local/bin/monmon
BINDIR=$MONMONDIR/bin
CONFDIR=$MONMONDIR/conf
CONFFILE=$CONFDIR/$1.conf
DATADIR=$MONMONDIR/data
LOGDIR=$MONMONDIR/log
LOGFILE=$LOGDIR/monmon.log
SHALIST=$DATADIR/$1.sha1
FILEHISTORY=$DATADIR/filehistory.csv
TMP=/tmp

MAILLOGFILE=$LOGDIR/mail.log
MAILSETTINGS=$CONFDIR/mail.conf
RAPPORTFILE=$LOGDIR/$1.rapport
RAPPORTFILE_TMP=$LOGDIR/$1.rapport.temp

HOSTNAME=`hostname | cut -d. -f1`
MAILRAPPORT=0

# voorbereiding script

if [ -f $RAPPORTFILE ];then
	rm -f $RAPPORTFILE
fi

if [ -f $RAPPORTFILE_TMP ];then
	rm -f $RAPPORTFILE_TMP
fi

if [ -f $SHALIST.added ];then
	rm -f $SHALIST.added
fi

if ! [ -f $CONFFILE ];then
	echo "[FATAL]: Geen $CONFFILE gevonden!!!"
	echo "[FATAL]: Einde script"
	exit 1
fi

if ! [ -f $SHALIST ];then
	echo "[INFO]: Geen $SHALIST gevonden."
fi


#functies 


#help boodschap
help(){
echo "usage: monmon.sh <dir-to-monitor>"
echo "<dir-to-monitor> is defined in $CONFDIR/ as <dir>.conf"
}

#tijdstempel

now(){

date +"%d/%m/%Y %H:%M:%S"
}

#mailen 

mail()
{

if [ "$mailto" == "" ];then
	source $MAILSETTINGS
fi

cat $RAPPORTFILE | $swaks --h-Subject "[MonMon] wijziging bestanden" --body - -t $mailto -server $mailsrv -from $mailfrom 2>&1 > /dev/null
MAILRESULT=$?
if [ "$MAILRESULT" == 0 ];then
	echo -e "`now` $RAPPORTFILE:verstuurd naar $mailto" | tee -a $MAILLOGFILE
else
      	echo -e "`now` $RAPPORTFILE: NIET verstuurd naar $mailto" | tee -a $MAILLOGFILE
       	echo -e "`now` Controleer de inhoud van $MAILSETTINGS"
fi
}

#Script


if ! [ -f $SHALIST ];then
	#nieuwe SHA1SUM lijst maken
	source $CONFFILE
	echo "`now`: SHA1SUM: CHECK:CREATE" | $tee -a $LOGFILE
	echo "servernaam: $HOSTNAME" | $tee -a $LOGFILE
	$find $DIR2SHA -maxdepth $MAXDEPTH -follow -type f -exec $sha1sum {} \; > $SHALIST
	echo "`now`: SHA1SUM: CHECK:END" | $tee -a $LOGFILE

else
	source $CONFFILE
	echo "`now`: SHA1SUM: CHECK:BEGIN"  >> $LOGFILE
	echo "servernaam: $HOSTNAME" | $tee -a $RAPPORTFILE $LOGFILE
	echo "directories: $DIR2SHA" | $tee -a $RAPPORTFILE $LOGFILE
	echo "bestanden: `wc -l $SHALIST|awk '{print $1}'`" | $tee -a $RAPPORTFILE $LOGFILE

	#lijst opbouwen van bestanden die gewijzigd zijn sinds laatste SHA1SUM check
	changedfiles=$($find $DIR2SHA -maxdepth $MAXDEPTH -follow -type f -newer $SHALIST)
	if ! [ "$changedfiles" == "" ];then
		for file in $changedfiles; do
			$grep -wi $file $SHALIST > /dev/null
       			GREPRESULT=$?
       			if [ "$GREPRESULT" == 1 ];then
               			echo $file >> $TMP/files.new
       			fi
		done
	fi
	
	echo "gekende SHA1SUM nakijken voor $DIR2SHA"
	$sha1sum -c $SHALIST --quiet 2>&1 >> $RAPPORTFILE_TMP
	echo "`now`: SHA1SUM: CHECK:END" >> $LOGFILE

	#nieuwe SHA1SUM lijst maken
	$find $DIR2SHA -maxdepth $MAXDEPTH -follow -type f -exec $sha1sum {} \; > $SHALIST


	#rapport opmaken
	#nieuwe bestanden
	if [ -s $TMP/files.new ]; then
		FILECOUNT=0
		echo -e "\nVolgende bestanden zijn NIEUW:"| $tee -a $RAPPORTFILE $LOGFILE 
		for file in `cat $TMP/files.new`; do
			FILECOUNT=`expr $FILECOUNT + 1`
               		echo "$FILECOUNT) $file (`stat -c%y $file| cut -c-19`)" | $tee -a $RAPPORTFILE $LOGFILE
               		echo "$file;NEW;`stat -c%y $file| cut -c-19`" >> $FILEHISTORY
		done
		MAILRAPPORT=1
	fi


	#gewijzigde bestanden
	grep -i 'failed$' $RAPPORTFILE_TMP|cut -d: -f1 > $TMP/files.changed
	if [ -s $TMP/files.changed ]; then
		FILECOUNT=0
		echo -e "\nVolgende bestanden zijn GEWIJZIGD:"  | $tee -a $RAPPORTFILE $LOGFILE 
		for file in `cat $TMP/files.changed`; do
			FILECOUNT=`expr $FILECOUNT + 1`
               		echo "$FILECOUNT) $file (`stat -c%y $file| cut -c-19`)" | $tee -a $RAPPORTFILE $LOGFILE
               		echo "$file;CHANGED;`stat -c%y $file| cut -c-19`"  >> $FILEHISTORY
		done
		MAILRAPPORT=1
	fi


	#verwijderde bestanden
	grep -i 'FAILED open or read$' $RAPPORTFILE_TMP| cut -d: -f1 > $TMP/files.deleted
	if [ -s $TMP/files.deleted ]; then
		FILECOUNT=0
		echo -e "\nVolgende bestanden zijn VERWIJDERD:"| $tee -a $RAPPORTFILE $LOGFILE 
		for file in `cat $TMP/files.deleted`; do
			FILECOUNT=`expr $FILECOUNT + 1`
               		echo "$FILECOUNT) $file" | $tee -a $RAPPORTFILE $LOGFILE
               		echo "$file;DELETED;" >> $FILEHISTORY
		done
		MAILRAPPORT=1
	fi

	#rapport doorsturen als er iets te melden valt

	if [ "$MAILRAPPORT" == 1 ];then
		mail
	fi

fi

#Tijdelijke bestanden verwijderen
rm -f $RAPPORTFILE_TMP 2>/dev/null
rm -f $TMP/files.new 2>/dev/null
rm -f $TMP/files.changed 2>/dev/null
rm -f $TMP/files.deleted 2>/dev/null
