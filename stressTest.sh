#!/bin/bash
# 
# Testscript om load te genereren op server om werkbare gegevens te hebben voor metricbeat
# you will need the binary: stress-ng 
# Run this script as ROOT 

# Setting variables 

logdir=/var/log
logfile=$logdir/stresstest.log

# Setting binary path
stress=/usr/bin/stress-ng

# Setting functions


#tijdstempel
now(){
date +"%d/%m/%y %H:%M:%S"
}

stressLogA(){
echo "$(now) [$actie]:Time2Run:$stressTime:START" >> $logfile
}

stressLogB(){
echo "$(now) [$actie]:Time2Run:$stressTime:END" >> $logfile
}

stressCPU(){
$stress --cpu $cpuAmount --cpu-method all -t $stressTime -v --log-file $logfile.tmp
}

stressMemory(){
$stress --brk 2 --stack 2 --bigheap 2 -t $stressTime -v --log-file $logfile.tmp
}


################
# start script #
################

clear

echo "           ################################"
echo "           # stress-ng: spread da stress! #"
echo "           ################################"


#check of gebruiker als root is aangemeld.
wiebenik=$(whoami)
if  [ $wiebenik != "root" ]; then
	echo "Log aan als root en voer dit script opnieuw uit"
	exit 1
fi

# Actie
echo "Welke component will je stressen: c(pu), m(emory), l(oad):"
read actie

echo "Hoelang wil je stressen?"
echo "1s, 5m, 1h"
read stressTime


if [ "$actie" == c ];then
	actie="CPU"
	stressLogA
	echo "Hoeveel CPU's wil je stressen (0:All)?"
	read cpuAmount

	stressCPU

elif [ "$actie" == m ];then
	actie="MEMORY"
	stressLogA

	stressMemory

elif [ "$actie" == l ];then
	actie="LOAD"
	stressLogA

	stressLoad

fi

#temp logfile samenvoegen met logfile
cat $logfile.tmp >> $logfile

#timestamp logfile
stressLogB
