#!/bin/bash
# 
# create a backup to Amazon S3
# to do: bedoeling is om een generiek backup script te maken waarbij:
# per applicatie een bestand.lst wordt geprocessed
# waarin de directories staan
# per applicatie 1 tarbestand dat dan naar s3 bucket wordt geupload.
# 
# Setting variables 

#program
tar=/bin/tar
gzip=/bin/gzip

#global
temp=/tmp
bindir=/var/www/dokuwiki/bin/custom/linux
hostdir=$bindir/hosts
logdir=$bindir/log
logfile=$logdir/backup.log

#functions

#timestamp
now(){
date +"%d%m%Y_%H%M"
}


#backup
dir2bu2=/tmp/test

# S3 
s3=/usr/bin/s3cmd
s3cfg=/var/www/dokuwiki/bin/custom/linux/.s3cfg
s3bucket="backup.bucky"

#script preparation
if ! [ -d $logdir ];then
        mkdir $logdir
fi

if ! [ -f $logfile ];then
        touch $logfile
fi

###################
# start of script #
###################

echo -e "`now`;script start" | tee -a $logfile

#reading dirs to backup
hosts2backup=$(find $hostdir -type f -printf %f\ )
echo "hosts to backup: $hosts2backup"

echo "folders to backup:"
#create timestamp	
timestamp=`now`

for host in $hosts2backup; do
	echo processing $host| tee -a $logfile

	#creating TAR file
	$tar -cf $dir2bu2/`echo $host`_$timestamp.tar --files-from /dev/null
	for dir in `cat $hostdir/$host`; do
		$tar -rf $dir2bu2/`echo $host`_$timestamp.tar $dir 
		tarresult=$?
		if [ "$tarresult" == 0 ];then
			echo -e "`now` TAR: added $dir successfully" | tee -a $logfile
		else
			echo -e "`now` TAR: added $dir NOT! successfully" | tee -a $logfile
		fi
	done

	#zipping TAR file
	$gzip $dir2bu2/`echo $host`_$timestamp.tar
	gzipresult=$?
		if [ "$gzipresult" == 0 ];then
			echo -e "`now` GZIP: gzipped TARfile successfully" | tee -a $logfile
		else
			echo -e "`now` GZIP: gzipped TARfile NOT! successfully" | tee -a $logfile
		fi

	#uploading TAR.GZ file
	$s3 -c $s3cfg put $dir2bu2/`echo $host`_$timestamp.tar.gz s3://$s3bucket
	s3result=$?
		if [ "$s3result" == 0 ];then
			echo -e "`now` S3: uploaded TAR.GZfile successfully" | tee -a $logfile
		else
			echo -e "`now` S3: uploaded TAR.GZfile unsuccessfully" | tee -a $logfile
		fi
done

echo -e "`now`;script end" | tee -a $logfile
