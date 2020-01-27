#!/bin/bash
#
# install bat executable
#
# Author: Koen Veys
# script is maintained in https://github.com/kveys/linux.git

#
# Setting variables 

#global
tmpdir=/tmp
bindir=/usr/local/bin
servername=`hostname`

#executables
wget=/usr/bin/wget
dpkg=/usr/bin/dpkg

#URL
batsrc="https://github.com/sharkdp/bat/releases/download/v0.12.1/bat_0.12.1_amd64.deb"

###################
# start of script #
###################

echo "donwloading bat file on $servername"
cd $tmp
$wget $batsrc

echo "installing bat on $servername"
$dpkg -i bat_0.12.1_amd64.deb
