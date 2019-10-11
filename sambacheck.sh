#!/bin/bash
########################################################################################
#
version=0.4.2
#
# script to check for possible reasons why samba/winbind fails 
# original version under gitlab.schaubroeck.be/systemen/klanten/linux/support
#
#############                                                              #############
#
# changelog
# Tue 24 sep 2019 - <sam.vankerckhoven@cipalschaubroeck.be> 0.4
#* make information more helpfull
#
# Mon 16 sep 2019 - <sam.vankerckhoven@cipalschaubroeck.be> 0.3
#* add help, verbose, version switches
#* visual aid for domain trusts
#* domain listing fix when hostname is part of domain
#* display samba version 
#
# Mon 16 sep 2019 - <sam.vankerckhoven@cipalschaubroeck.be> 0.1
#* To gitlab
# 
# Mon 16 sep 2019 - <sam.vankerckhoven@cipalschaubroeck.be> 0.0
#* Conception
# 
###############################
# 
# todo
# * move script gitlab
# 
# 

### DECLARATIONS
# RGB format '\e[48;5;185m'
logfile=/var/log/check_samba.log
GREEN_CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
RED_CROSS_MARK="\033[0;31m\xE2\x9C\x98\033[0m"
FILLED_CIRCLE="\033[0;34m\xE2\x97\x8F\033[0m"
FILLED_CIRCLE2="\033[0;32m\xE2\x8A\x99\033[0m"
YELLOW="\033[0;33m"
LBLUE="$(tput setaf 4)"
W_ON_BLUE="\033[0;44m"
W_ON_RED="\033[0;41m"
W_ON_GRAY='\e[48;5;244m'
WHITE="$(tput sgr 0)"
ceol=$(tput el)
COLSPC=46 # Spacing for the 2nd Column
TABLEWIDTH=80
TITLE="${W_ON_BLUE}%-${TABLEWIDTH}s"
DTITLE="${W_ON_BLUE}%-$((COLSPC-2))s%-$((TABLEWIDTH - COLSPC + 2))s"
COLUMN3TITLE="${W_ON_BLUE}%-$((COLSPC-2))s%-$((TABLEWIDTH - (COLSPC + 14)))s%-16s"
DTITLE2="${W_ON_GRAY}%-$((COLSPC-2))s%-$((TABLEWIDTH - COLSPC + 2))s"
DTITLE_WARNING="${W_ON_RED}%-$((COLSPC-2))s%-$((TABLEWIDTH - COLSPC + 2))s"
LIST=" ${FILLED_CIRCLE} %-$((TABLEWIDTH-8))s"

### FUNCTIONS

function usage() {
    cat <<EOF 
    Usage: $0 [OPTIONS]
    Version: ${version}

    Check for problems with samba

    OPTIONS:
      -v                show bash verbosity (set -x)   
      -V,               Show Version   
      -y,               Skip samba version check (use when YUM is occupied)           
      -h 	            Show this help
      
    NOT YET IMPLEMENTED:  
      -r		        restart/reload related services
      -l,               show which logs to check
      
    For bug reporting instructions, please contact:
    <sam.vankerckhoven@cipalschaubroeck.be>.
EOF
}

function getargs() {
    while getopts "vhV" o; do
	#log "Switch: ${o}	${OPTARG}"
	    case "${o}" in

        v)
            set -x
            log "Script Version: ${version}"
        ;;

	h)
	    usage
            exit 0
	;;

	V)
	    printf "%s\tVersion: %s\n" "$0" "${version}"
	    exit 0
	;;

        y)
            skip_yum=y
        ;;
    
	    
	*)
            usage
            exit 1
        ;;

	    esac
    done
}

function log(){
    msg=${@}
    printf "$(date '+%Y-%m-%d %T') [-] %s\n" "${msg}" >> ${logfile}
}

function check_services(){
    printf "${TITLE}${WHITE}\n" "Services"
    for serv in smb nmb winbind
    do
        service ${serv} status > /dev/null
        [[ $? -eq 0 ]] && result=${GREEN_CHECK_MARK} || result=${RED_CROSS_MARK}
        printf "  %-$((COLSPC-2))s${result}\n" "${serv}"
    done
}
function nmb_lookup() {
    fqdntarget=$1
    target=${fqdntarget/.*}
    address=$(nmblookup ${target} | sed -ne '/positive/ s:.*(\ \(.*\)\ ):\1:p')
    echo ${address}
}
function validate_configs() {
    printf "${TITLE}${WHITE}\n" "Validate Configs"
    validate_samba_config
    validate_krb5_config
    
}
function get_fqdn(){
    FQDN=$(wbinfo --domain-info $1 | sed -ne '/Alt_Name/ s:.*\:\ \(.*\):\1:p')
    echo ${FQDN}
}

function lookup_dcs() {
    fqdn_dom=$(get_fqdn $1)
    dcs=$(host -t srv _kerberos._tcp.${fqdn_dom} | awk '{print $8}')
    for DC in ${dcs[@]}
    do
        printf "  ${FILLED_CIRCLE2} %-$((COLSPC + 6))s\t${YELLOW}%s${WHITE}\n" "${DC}" "$(nmb_lookup ${DC})"   
    done
}

function validate_krb5_config() {
    VALID=0
    [[ ! "$(grep -i example /etc/krb5.conf)" == "" ]] && VALID=1
    [[ ${VALID} -eq 0 ]] && result=${GREEN_CHECK_MARK} || result=${RED_CROSS_MARK}
    printf "${LIST}${result}\n" "/etc/krb5.conf"
    
}
function validate_samba_config() {
    testparm -s > /dev/null 2&>1
    [[ $? -eq 0 ]] && result=${GREEN_CHECK_MARK} || result=${RED_CROSS_MARK}
    printf "${LIST}${result}\n" "/etc/samba/smb.conf"
}
function check_dc_name(){
    dom=$(get_fqdn $1)
    wbinfo --dsgetdcname=${dom} > /dev/null
    [[ $? -eq 0 ]] && result=${GREEN_CHECK_MARK} || result=${RED_CROSS_MARK}
    echo ${result}
}
function checktrust(){
    wbinfo --domain-info $1 > /dev/null
    [[ $? -eq 0 ]] && result=${GREEN_CHECK_MARK} || result=${RED_CROSS_MARK}
    echo ${result}
}
function list_domains(){
    hostname_lower=$(hostname)
    PC_DOM=${hostname_lower^^}
    DOMAINS=$(wbinfo -m | grep -v "^${PC_DOM}$" | grep -v BUILTIN)
    log Domains found: ${DOMAINS[@]}
    printf "${COLUMN3TITLE}${WHITE}\n" "Domains - Check NameServers" "DomInfo" "DC"
    for DOM in ${DOMAINS[@]}
    do
        TRUST=$(checktrust ${DOM})
        DC=$(check_dc_name ${DOM})
        printf " ${FILLED_CIRCLE} %-$((COLSPC-3))s${TRUST}%-18s${DC}\n" "${DOM}" " "
        lookup_dcs ${DOM}
    done

}
function check_join() {
    WBINFO=$(wbinfo -t)
    printf "${TITLE}${WHITE}\n" "Check Trust Pre-WIN2000"
    printf "${WBINFO}\n"
    check_net_ads_info
}
function check_net_ads_info(){
    printf "${TITLE}${WHITE}\n" "Check Trust Net ADS"
    net ads info | grep 'server\|Realm'
}
function check_samba_version()
{
    if [[ -z ${skip_yum} ]]
    then
        smbpkg=$(yum list installed | grep '^samba.\?\.x86_64')
        if [[ -z ${smbpkg} ]] 
        then
            smbver="Not Installed"
            printf "${DTITLE_WARNING}${WHITE}\n" "Samba Version" "${smbver}"
        else
            minusfront=${smbpkg#*\ }
            smbver=${minusfront%%-*}
            printf "${DTITLE2}${WHITE}\n" "Samba Version" "${smbver}"
        fi
    fi
}
### MAIN
getargs ${@}
check_samba_version
validate_configs
check_services        
list_domains
check_join
