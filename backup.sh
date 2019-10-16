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

#global
temp=/tmp
logdir=/tmp
logfile=$logdir/backup.log

now(){
date +"%d/%m/%Y_%H:%M:%S"
}


#backup
apps2backup=$(find . -name '*.lst' -printf %f\ )
dir2bu2=/tmp/test
bufile=

# S3 
s3=/usr/bin/s3cmd
s3config=/var/www/dokuwiki/bin/custom/linux/.s3cfg
s3bucket=

#start of script
echo -e "`now`;script start" | tee -a $logfile

#reading dirs to backup
echo $apps2backup
for file in $apps2backup; do
	echo processing $file
	for dir in `cat $file`; do
		echo "backing up $dir"
#		$tar -cvzf $dir2bu2/`echo $now`.tar.gz $dir 
	done
done
	
#creating TAR file
#$tar -cvzf $dir2bu2/$today.tar.gz $dir 
#tarresult=$?
#if [ "$tarresult" == 0 ];then
#	echo -e "`now` tar created successfully" | tee -a $logfile
#else
#	echo -e "`now` tar created NOT successfully" | tee -a $logfile
#fi

#uploading TAR file
#$s3 put  [FILE...] s3://BUCKET[/PREFIX]

