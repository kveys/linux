#!/bin/bash
#
# install Linux scripts
#
# Author: Koen Veys
# script is maintained in https://github.com/kveys/linux.git

#
# Setting variables 

#global
tmpdir=/tmp
bindir=/usr/local/bin
servername=`hostname`

###################
# start of script #
###################

echo "installing linux script on $servername"

mv $tmpdir/linux/modfinder.sh $bindir
