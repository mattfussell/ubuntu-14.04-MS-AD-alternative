#!/bin/bash
# this script was written for Ubuntu 14.04 server
# This script should be ran as root.

# this script must be executed as root.
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mYOU MUST BE ROOT TO RUN THIS SCRIPT! \e[0m \n"
    exit 1
    else echo -e "Root privileges verified; proceeding. \n"
fi

# Variable for controlling backup files
tmstamp=`date --rfc-3339=ns | sed 's/ /./g'`
# Variable for augmenting resolvconf
# default: /etc/resolvconf/resolv.conf.d/head
rslvConf="/etc/resolvconf/resolv.conf.d/head"
# Variable for rewriting dnsmasq.conf
# default: /etc/dnsmasq.conf
dnsConf="/etc/dnsmasq.conf"
# Variable for rewriting ntp.conf 
# default /etc/ntp.conf
ntpCfg="/etc/ntp.conf"
# Variable for adding ntp synchronization to CRON
# default /etc/cron.daily/ntpdate
cronDF="/etc/cron.daily/ntpdate"
# Variable for controlling sudoers file entry
# default: /etc/sudoers
sudrs="/etc/sudoers"
# Variable for controlling ldapscripts defaults
# default: /etc/ldapscripts/ldapscripts.conf
ldapScrCnf="/etc/ldapscripts/ldapscripts.conf"
# Variable for controlling default OUs
struct="structure.ldif"
# Variable for controlling LDAP Indexing options
index="index.ldif"
# Variable for controlling autofs LDIF
afsl="autofs.ldif"
# Variable for controlling automount LDIF
atml="automount.ldif"
# Variable for controlling sudo schema
sudl="sudo.ldif"
# Variable for implementing sudo schema
sudml="sudoMaster.ldif"
# Variable for controlling the default LDAP password file
# default: /etc/ldapscripts/ldapscripts.passwd
passFile="/etc/ldapscripts/ldapscripts.passwd"
# Variable for controlling kadm5.acl
# default: /etc/krb5kdc/kadm5.acl
k5acl="/etc/krb5kdc/kadm5.acl"
# Variable for controlling krb5.conf
# default /etc/krb5.conf
k5conf="/etc/krb5.conf"
# Variable for controlling sssd.conf
# This file is not generated by default; a generic sample file
# can be found in /usr/share/doc/sssd-common/examples/sssd-example.conf
sdcnf="/etc/sssd/sssd.conf"
# Variable for controlling the sshd_conf file
# default: /etc/ssh/sshd_config
sshFile="/etc/ssh/sshd_config"
# Variable for controlling fstab file
# default: /etc/fstab
fstb="/etc/fstab"
# Variable for controlling export file
# default: /etc/exports
xprts="/etc/exports"
# Variable for controlling nfs-common
# default: /etc/default/nfs-common
nfscmn="/etc/default/nfs-common"
# Variable for controlling nfs-kernel-server
# default: /etc/default/nfs-kernel-server
nksrv="/etc/default/nfs-kernel-server"
# Variable for controlling idmapd.conf
# default: /etc/idmapd.conf
idmpd="/etc/idmapd.conf"

# These are variables to be adjusted as necessary
serverIP="localhost" # default: localhost
krbadmin="administrator" # default Kerberos administrator
ldadmin="admin" # default LDAP administrator
admin="administrator" # default system administrative user
srvrName="main1" # server name
dc1="test" # default: example
dc2="local" # default: com
newIP="192.168.1.50" # new machine IP
newMask="255.255.255.0" # new netmask
newGate="192.168.1.1" # new network gateway
newNet="192.168.1.0" # new network address
newBrd="192.168.1.255" # new broadcast address
newDNS1="192.168.1.50" # new primary DNS
newDNS2="8.8.8.8" # new secondary DNS
newDNS3="8.8.4.4" # new tertiary DNS
intf="eth0" # primary ethernet interface
ldapPass="password" # your LDAP admin password
userVar="users" # your default user ou
groupVar="groups" # your default group ou
machVar="machines" # your default machines ou
users="domainusers" # default user group
admins="domainadmins" # default admin group
#ntpSrvr="" # use to define external NTP server
dhcpUp="192.168.1.250" # upper DHCP limit
dhcpLw="192.168.1.100" # lower DHCP limit
leaseTm="8h" # dhcp lease time
#============================================#
#     Derived variables in this section      #
#============================================#
newDom="$dc1.$dc2" # concatenated domain name
oct1=`echo $newIP | cut -d. -f1`
oct2=`echo $newIP | cut -d. -f2`
oct3=`echo $newIP | cut -d. -f3`
oct4=`echo $newIP | cut -d. -f4`
newIPRev="$oct4.$oct3.$oct2.$oct1" # reversed IP Address
newDomUp=`echo $newDom | tr '[:lower:]' '[:upper:]'` # capitalized newDom

# Create update script
upd8="/home/$admin/bin/updateServer.sh"
mkdir /home/$admin/bin
touch $upd8
echo "#!/bin/bash" >> $upd8
echo "# This script written for Ubuntu 14.04 Server" >> $upd8
echo "sudo apt-get update" >> $upd8
echo "sudo aptitude safe-upgrade -y" >> $upd8
echo "sudo apt-get autoremove -y" >> $upd8
echo "sudo apt-get autoclean -y" >> $upd8
chmod +x $upd8
chown $admin:$admin /home/$admin/bin
chown $admin:$admin $upd8

# Install updates for base system
apt-get update
aptitude install -y openssh-server
aptitude safe-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# Backup and replace /etc/hosts
newHosts="/etc/hosts"
mv $newHosts $newHosts.back.$tmstamp
touch $newHosts
echo "127.0.0.1    localhost.localdomain    localhost" >> $newHosts
echo "$newIP    $srvrName.$newDom    $srvrName" >> $newHosts
echo "" >> $newHosts
echo "::1    localhost    ip6-localhost    ip6-loopback" >> $newHosts
echo "ff02::1    ip6-allnodes" >> $newHosts
echo "ff02::2    ip6-allrouters" >> $newHosts

# Backup and replace /etc/network/interfaces
newIF="/etc/network/interfaces"
mv $newIF $newIF.back.$tmstamp
touch $newIF
echo "auto lo" >> $newIF
echo "iface lo inet loopback" >> $newIF
echo "" >> $newIF
echo "auto eth0" >> $newIF
echo "iface eth0 inet static" >> $newIF
echo "    address $newIP" >> $newIF
echo "    netmask $newMask" >> $newIF
echo "    gateway $newGate" >> $newIF
echo "    network $newNet" >> $newIF
echo "    broadcast $newBrd" >> $newIF
echo "    dns-nameservers $newIP, $newDNS2, $newDNS3" >> $newIF

# Add information to resolvconf
mv $rslvConf $rslvConf.back.$tmstamp
touch $rslvConf
echo "domain $dc1.$dc2" >> $rslvConf
echo "search $dc1.$dc2" >> $rslvConf
echo "nameserver $newIP" >> $rslvConf

# Change hostname and restart interface
hostnamectl set-hostname $srvrName.$newDom
service network-interface restart INTERFACE="$intf"

# Install dnsmasq
aptitude install dnsmasq -y

# Add an external host file for dnsmasq
touch /etc/hosts.dnsmasq

# Reconfigure dnsmasq
mv $dnsConf $dnsConf.back.$tmstamp
touch $dnsConf
echo "# Use a specific hosts file for dnsmasq" >> $dnsConf
echo "no-hosts" >> $dnsConf
echo "addn-hosts=/etc/hosts.dnsmasq" >> $dnsConf
echo "" >> $dnsConf
echo "# DNS settings for the network" >> $dnsConf
echo "server=/localnet/$newIP" >> $dnsConf
echo "server=/#/$newDNS2" >> $dnsConf
echo "server=/#/$newDNS3" >> $dnsConf
echo "" >> $dnsConf
echo "# set dhcp options" >> $dnsConf
echo "dhcp-option=19,0                # option ip-forwarding off" >> $dnsConf
echo "dhcp-option=44,0.0.0.0             # set netbios-over-TCP/IP nameserver(s) aka WINS ser$" >> $dnsConf
echo "dhcp-option=45,0.0.0.0            # netbios datagram distribution server" >> $dnsConf
echo "dhcp-option=46,8                # netbios node type" >> $dnsConf
echo "" >> $dnsConf
echo "domain=$newDom                # sets domain to be used" >> $dnsConf
echo "dhcp-range=$dhcpLw,$dhcpUp,$leaseTm    # sets IP lease range and lease time" >> $dnsConf
echo "dhcp-option=option:router,$newGate        # sets gateway address" >> $dnsConf
echo "dhcp-option=option:ntp-server,$newIP    # sets the NTP server for the network" >> $dnsConf
echo "dhcp-authoritative                # make this the authoritative DHCP server" >> $dnsConf
echo "" >> $dnsConf
echo "# DNS settings for this server" >> $dnsConf
echo "# (required for Kerberos)" >> $dnsConf
echo "ptr-record=$newIPRev.in-addr.arpa.,\"$srvrName.$newDom\"" >> $dnsConf
echo "address=/$srvrName.$newDom/$newIP" >> $dnsConf
echo "" >> $dnsConf
echo "# Kerberos and LDAP automatic settings" >> $dnsConf
echo "# automatically maps Kerberos and LDAP" >> $dnsConf
echo "# to DHCP Clients, making them realm-aware" >> $dnsConf
echo "address=/kerberos.$newDom/$newIP" >> $dnsConf
echo "address=/ldap.$newDom/$newIP" >> $dnsConf
echo "" >> $dnsConf
echo "txt-record=_kerberos.$newDom,\"$newDomUp\"" >> $dnsConf
echo "srv-host=_udp.$newDom,\"kerberos.$newDom\",88" >> $dnsConf
echo "srv-host=_tcp.$newDom,\"kerberos.$newDom\",88" >> $dnsConf
echo "srv-host=_kerberos-master._udp.$newDom,\"kerberos.$newDom\",88" >> $dnsConf
echo "srv-host=_kerberos-adm._tcp.$newDom,\"kerberos.$newDom\",749" >> $dnsConf
echo "srv-host=_kpasswd._udp.$newDom,\"kerberos.$newDom\",464" >> $dnsConf
echo "" >> $dnsConf
echo "srv-host=_ldap._tcp.$newDom,ldap.$newDom,389" >> $dnsConf

# Restart dnsmasq
service dnsmasq restart

# install NTP    
apt-get install ntp ntpdate -y

# back up and re-write NTP config file
mv $ntpCfg $ntpCfg.back.$tmstamp
touch $ntpCfg
# enable statistics logging
echo "statsdir /var/log/ntpstats" >> $ntpCfg
echo "driftfile /var/lib/ntp/ntp.drift" >> $ntpCfg
echo "statistics loopstats peerstats clockstate" >> $ntpCfg
echo "filegen loopstats file loopstats type day enable" >> $ntpCfg
echo "filegen peerstats file peerstats type day enable" >> $ntpCfg
echo "filegen clockstats file clockstats type day enable" >> $ntpCfg
# specify NTP servers, including local NIST for US (this one for CST)
echo "server 0.ubuntu.pool.ntp.org" >> $ntpCfg
echo "server 1.ubuntu.pool.ntp.org" >> $ntpCfg
echo "server 2.ubuntu.pool.ntp.org" >> $ntpCfg
echo "server 3.ubuntu.pool.ntp.org" >> $ntpCfg
echo "server pool.ntp.org" >> $ntpCfg
echo "server ntp.ubuntu.com" >> $ntpCfg
# put additional local time servers here
echo "server nist.time.nosc.us" >> $ntpCfg # Carrollton, TX 96.226.242.9
# set access control
echo "restrict -4 default kod notrap nomodify nopeer noquery" >> $ntpCfg
echo "restrict -6 default kod notrap nomodify nopeer noquery" >> $ntpCfg
echo "restrict 127.0.0.1" >> $ntpCfg
echo "restrict ::1" >> $ntpCfg
# provide time for local subnet
echo "broadcast $newBrd" >> $ntpCfg

touch $cronDF
echo "ntpdate ntp.ubuntu.com pool.ntp.org nist.time.nosc.us" >> $cronDF
chmod 755 $cronDF

# Restart the NTP server
service ntp restart

# Install required software - there will be prompts to
# set required variables for LDAP; remember - what you
# put in when prompted must match the variables in this
# script.
aptitude install slapd ldap-utils ldapscripts libnss-ldapd libpam-ldapd -y 

# Write default structure file
touch $struct
echo "dn: ou=$userVar,dc=$dc1,dc=$dc2" >> $struct
echo "objectClass: organizationalUnit" >> $struct
echo "ou: $userVar" >> $struct
echo "" >> $struct
echo "dn: ou=$groupVar,dc=$dc1,dc=$dc2" >> $struct
echo "objectClass: organizationalUnit" >> $struct
echo "ou: $groupVar" >> $struct
echo "" >> $struct
echo "dn: ou=$machVar,dc=$dc1,dc=$dc2" >> $struct
echo "objectClass: organizationalUnit" >> $struct
echo "ou: $machVar" >> $struct

# Write default index file
touch $index
echo "dn: olcDatabase={1}hdb,cn=config" >> $index
echo "changetype: modify" >> $index
echo "add: olcDbIndex" >> $index
echo "olcDbIndex: uidNumber eq" >> $index
echo "olcDbIndex: gidNumber eq" >> $index
echo "olcDbIndex: loginshell eq" >> $index
echo "olcDbIndex: uid eq,pres,sub" >> $index
echo "olcDbIndex: memberUid eq,pres,sub" >> $index
echo "olcDbIndex: uniqueMember eq,pres" >> $index

# Write autofs.ldif file
touch $afsl
echo "dn: cn=autofs,cn=schema,cn=config" >> $afsl
echo "objectClass: olcSchemaConfig" >> $afsl
echo "cn: autofs" >> $afsl
echo "olcAttributeTypes: {0}( 1.3.6.1.1.1.1.25 NAME 'automountInformation' DESC 'Information used by the autofs automounter' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 SINGLE-VALUE )" >> $afsl
echo "olcObjectClasses: {0}( 1.3.6.1.1.1.1.13 NAME 'automount' DESC 'An entry in an automounter map' SUP top STRUCTURAL MUST ( cn \$ automountInformation \$ objectclass ) MAY description )" >> $afsl
echo "olcObjectClasses: {1}( 1.3.6.1.4.1.2312.4.2.2 NAME 'automountMap' DESC 'An group of related automount objects' SUP top STRUCTURAL MUST ou )" >> $afsl

# Write the automount.ldif
touch $atml
echo "dn: ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "ou: $admin" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: organizationalUnit" >> $atml
echo "" >> $atml
echo "dn: ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "ou: automount" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: organizationalUnit" >> $atml
echo "" >> $atml
echo "dn: ou=auto.master,ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "ou: auto.master" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: automountMap" >> $atml
echo "" >> $atml
echo "dn: cn=/home,ou=auto.master,ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "cn: /home" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: automount" >> $atml
echo "automountInformation: ldap:ou=auto.home,ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2 --timeout=60 --ghost" >> $atml
echo "" >> $atml
echo "dn: ou=auto.home,ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "ou: auto.home" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: automountMap" >> $atml
echo "" >> $atml
echo "dn: cn=/,ou=auto.home,ou=automount,ou=$ldadmin,dc=$dc1,dc=$dc2" >> $atml
echo "cn: /" >> $atml
echo "objectClass: top" >> $atml
echo "objectClass: automount" >> $atml
echo "automountInformation: -fstype=nfs4,rw,hard,intr,fsc,sec=krb5 $srvrName.$dc1.$dc2:/home/\$" >> $atml

# Write sudo.ldif
touch $sudl
echo "dn: cn=sudo,cn=schema,cn=config" >> $sudl
echo "objectClass: olcSchemaConfig" >> $sudl
echo "cn: sudo" >> $sudl
echo "olcAttributeTypes: {0}( 1.3.6.1.4.1.15953.9.1.1 NAME 'sudoUser' DESC 'User(s) who may  run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {1}( 1.3.6.1.4.1.15953.9.1.2 NAME 'sudoHost' DESC 'Host(s) who may run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {2}( 1.3.6.1.4.1.15953.9.1.3 NAME 'sudoCommand' DESC 'Command(s) to be executed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {3}( 1.3.6.1.4.1.15953.9.1.4 NAME 'sudoRunAs' DESC 'User(s) impersonated by sudo (deprecated)' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {4}( 1.3.6.1.4.1.15953.9.1.5 NAME 'sudoOption' DESC 'Option(s) followed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {5}( 1.3.6.1.4.1.15953.9.1.6 NAME 'sudoRunAsUser' DESC 'User(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {6}( 1.3.6.1.4.1.15953.9.1.7 NAME 'sudoRunAsGroup' DESC 'Group(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )" >> $sudl
echo "olcAttributeTypes: {7}( 1.3.6.1.4.1.15953.9.1.8 NAME 'sudoNotBefore' DESC 'Start of time interval for which the entry is valid' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 )" >> $sudl
echo "olcAttributeTypes: {8}( 1.3.6.1.4.1.15953.9.1.9 NAME 'sudoNotAfter' DESC 'End of time interval for which the entry is valid' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 )" >> $sudl
echo "olcAttributeTypes: {9}( 1.3.6.1.4.1.15953.9.1.10 NAME 'sudoOrder' DESC 'an integer to order the sudoRole entries' EQUALITY integerMatch ORDERING integerOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 )" >> $sudl
echo "olcObjectClasses: {0}( 1.3.6.1.4.1.15953.9.2.1 NAME 'sudoRole' DESC 'Sudoer Entries' SUP top STRUCTURAL MUST cn MAY ( sudoUser \$ sudoHost \$ sudoCommand \$ sudoRunAs \$ sudoRunAsUser \$ sudoRunAsGroup \$ sudoOption \$ sudoOrder \$ sudoNotBefore \$ sudoNotAfter \$ description ) )" >> $sudl

# Write sudoMaster.ldif
touch $sudml
echo "dn: ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectclass: organizationalUnit" >> $sudml
echo "objectclass: top" >> $sudml
echo "ou: sudoers" >> $sudml
echo "" >> $sudml
echo "dn: cn=defaults,ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectClass: top" >> $sudml
echo "objectClass: sudoRole" >> $sudml
echo "cn: defaults" >> $sudml
echo "description: Default sudoOptions go here" >> $sudml
echo "sudoOption: env_reset" >> $sudml
echo "sudoOption: mail_badpass" >> $sudml
echo "sudoOrder: 1" >> $sudml
echo "" >> $sudml
echo "dn: cn=root,ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectClass: top" >> $sudml
echo "objectClass: sudoRole" >> $sudml
echo "cn: root" >> $sudml
echo "sudoUser: root" >> $sudml
echo "sudoHost: ALL" >> $sudml
echo "sudoRunAsUser: ALL" >> $sudml
echo "sudoRunAsGroup: ALL" >> $sudml
echo "sudoCommand: ALL" >> $sudml
echo "sudoOrder: 2" >> $sudml
echo "" >> $sudml
echo "dn: cn=%admin,ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectClass: top" >> $sudml
echo "objectClass: sudoRole" >> $sudml
echo "cn: %admin" >> $sudml
echo "sudoUser: %admin" >> $sudml
echo "sudoHost: ALL" >> $sudml
echo "sudoRunAsUser: ALL" >> $sudml
echo "sudoCommand: ALL" >> $sudml
echo "sudoOrder: 3" >> $sudml
echo "" >> $sudml
echo "dn: cn=%sudo,ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectClass: top" >> $sudml
echo "objectClass: sudoRole" >> $sudml
echo "cn: %sudo" >> $sudml
echo "sudoUser: %sudo" >> $sudml
echo "sudoHost: ALL" >> $sudml
echo "sudoRunAsUser: ALL" >> $sudml
echo "sudoRunAsGroup: ALL" >> $sudml
echo "sudoCommand: ALL" >> $sudml
echo "sudoOrder: 4" >> $sudml
echo "" >> $sudml
echo "dn: cn=%$admins,ou=sudoers,dc=$dc1,dc=$dc2" >> $sudml
echo "objectClass: top" >> $sudml
echo "objectClass: sudoRole" >> $sudml
echo "cn: %$admins" >> $sudml
echo "sudoUser: %$admins" >> $sudml
echo "sudoHost: ALL" >> $sudml
echo "sudoRunAsUser: ALL" >> $sudml
echo "sudoRunAsGroup: ALL" >> $sudml
echo "sudoCommand: ALL" >> $sudml
echo "sudoOrder: 5" >> $sudml

# Add the structure file to LDAP
ldapadd -x -D cn=$ldadmin,dc=$dc1,dc=$dc2 -W -f $struct
mv $struct $struct.back

# Run the indexing modification
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f $index
mv $index $index.back

# Run the autofs modification
ldapadd -Y EXTERNAL -H ldapi:/// -f $afsl
mv $afsl $afsl.back

# Run the autmount modification
ldapadd -D cn=$ldadmin,dc=$dc1,dc=$dc2 -W -f $atml
mv $atml $atml.back

# Run the sudo modification
ldapadd -Y EXTERNAL -H ldapi:/// -f $sudl
mv $sudl $sudl.back

# Run the sudoMaster modification
ldapadd -f $sudml -D "cn=$ldadmin,dc=$dc1,dc=$dc2" -W -x
mv $sudml $sudml.back

# Write password file for ldapscripts
touch $passFile
echo -n "$ldapPass" > $passFile

# Rewrite ldapscripts.conf
mv $ldapScrCnf $ldapScrCnf.back.$tmstamp
touch $ldapScrCnf
echo "SERVER=\"ldap://$serverIP\"" >> $ldapScrCnf
echo "SUFFIX=\"dc=$dc1,dc=$dc2\"" >> $ldapScrCnf
echo "GSUFFIX=\"ou=$groupVar\"" >> $ldapScrCnf
echo "USUFFIX=\"ou=$userVar\"" >> $ldapScrCnf
echo "MSUFFIX=\"ou=$machVar\"" >> $ldapScrCnf
echo "SASLAUTH=\"\"" >> $ldapScrCnf
echo "BINDDN=\"cn=$ldadmin,dc=$dc1,dc=$dc2\"" >> $ldapScrCnf
echo "BINDPWDFILE=\"$passFile\"" >> $ldapScrCnf
echo "GIDSTART=\"10000\"" >> $ldapScrCnf
echo "UIDSTART=\"10000\"" >> $ldapScrCnf
echo "MIDSTART=\"20000\"" >> $ldapScrCnf
echo "GCLASS=\"posixGroup\"" >> $ldapScrCnf
echo "CREATEHOMES=\"yes\"" >> $ldapScrCnf
echo "PASSWORDGEN=\"pwgen\"" >> $ldapScrCnf
echo "RECORDPASSWORDS=\"no\"" >> $ldapScrCnf
echo "PASSWORDFILE=\"/var/log/ldapscripts_passwd.log\"" >> $ldapScrCnf
echo "LOGFILE=\"/var/log/ldapscripts.log\"" >> $ldapScrCnf
echo "LDAPSEARCHBIN=\"/usr/bin/ldapsearch\"" >> $ldapScrCnf
echo "LDAPADDBIN=\"/usr/bin/ldapadd\"" >> $ldapScrCnf
echo "LDAPDELETEBIN=\"/usr/bin/ldapdelete\"" >> $ldapScrCnf
echo "LDAPMODIFYBIN=\"/usr/bin/ldapmodify\"" >> $ldapScrCnf
echo "LDAPMODRDNBIN=\"/usr/bin/ldapmodrdn\"" >> $ldapScrCnf
echo "LDAPPASSWDBIN=\"/usr/bin/ldappasswd\"" >> $ldapScrCnf
echo "LDAPSEARCHOPTS=\"-o ldif-wrap=no\"" >> $ldapScrCnf
echo "GETENTPWCMD=\"\"" >> $ldapScrCnf
echo "GETENTGRCMD=\"\"" >> $ldapScrCnf
echo "GTEMPLATE=\"\"" >> $ldapScrCnf
echo "UTEMPLATE=\"\"" >> $ldapScrCnf
echo "MTEMPLATE=\"\"" >> $ldapScrCnf

# Give the new admin groups SUDO access
echo "" >> $sudrs
echo "# Entry to allow LDAP $admins group to have SUDO access:" >> $sudrs
echo "%$admins    ALL=(ALL) ALL" >> $sudrs

# Establish LDAP groups for our users
ldapaddgroup $admins
ldapaddgroup $users

# Store backup files
mkdir ldap_config_backups
chown $admin:$admin *.back
mv *.back ldap_config_backups/
chown $admin:$admin ldap_config_backups

# Install Kerberos
aptitude install krb5-kdc krb5-admin-server -y
krb5_newrealm

# Create a Kerberos administrative user
kadmin.local -q "addprinc $krbadmin/admin"

# Modify the Kerberos ACL 
mv $k5acl $k5acl.back.$tmstamp
touch $k5acl
echo "# This file is the access control list for krb5 administration." >> $k5acl
echo "# To enable adminstration rights to any principle ending in /admin," >> $k5acl
echo "# ensure the following line is uncommented:" >> $k5acl
echo "*/admin *" >> $k5acl

# Modify krb5.conf
mv $k5conf $k5conf.back.$tmstamp
touch $k5conf
echo "[libdefaults]" >> $k5conf
echo "    default_realm = $newDomUp" >> $k5conf
echo "    krb4_config = /etc/krb.conf" >> $k5conf
echo "    krb4_realms = /etc/krb.realms" >> $k5conf
echo "    kdc_timesync = 1" >> $k5conf
echo "    ccache_type = 4" >> $k5conf
echo "    forwardable = true" >> $k5conf
echo "    proxiable = true" >> $k5conf
echo "    allow_weak_crypto = true" >> $k5conf
echo "    v4_instance_resolve = false" >> $k5conf
echo "    vr_name_convert = {" >> $k5conf
echo "        host = {" >> $k5conf
echo "            rcmd = host" >> $k5conf
echo "            ftp = ftp" >> $k5conf
echo "        }" >> $k5conf
echo "        plain = {" >> $k5conf
echo "            something = something-else" >> $k5conf
echo "        }" >> $k5conf
echo "    }" >> $k5conf
echo "    fcc-mit-ticketflags = true" >> $k5conf
echo "" >> $k5conf
echo "[realms]" >> $k5conf
echo "    $newDomUp = {" >> $k5conf
echo "        kdc = $srvrName.$newDom" >> $k5conf
echo "        admin_server = $srvrName.$newDom" >> $k5conf
echo "        master_kdc = $srvrName.$newDom" >> $k5conf
echo "        default_domain = $newDom" >> $k5conf
echo "    }" >> $k5conf
echo "" >> $k5conf
echo "[domain_realm]" >> $k5conf
echo "" >> $k5conf
echo "[login]" >> $k5conf
echo "    krb4_convert = true" >> $k5conf
echo "    krb4_get_tickets = false" >> $k5conf

# Restart Kerberos to pick up the changes
service krb5-admin-server restart

# Install SSSD
aptitude install -y sssd

# Create the sssd.conf file
touch $sdcnf
echo "[sssd]" >> $sdcnf
echo "config_file_version = 2" >> $sdcnf
echo "reconnection_retries = 3" >> $sdcnf
echo "sbus_timeout = 30" >> $sdcnf
echo "services = nss, pam, sudo" >> $sdcnf
echo "domains = $newDom" >> $sdcnf
echo "" >> $sdcnf
echo "[nss]" >> $sdcnf
echo "filter_groups = root" >> $sdcnf
echo "filter_users = root" >> $sdcnf
echo "reconnection_retries = 3" >> $sdcnf
echo "" >> $sdcnf
echo "[pam]" >> $sdcnf
echo "reconnection_retries = 3" >> $sdcnf
echo "" >> $sdcnf
echo "[domain/$newDom]" >> $sdcnf
echo "; Using enumerate = true leads to high load and slow response" >> $sdcnf
echo "enumerate = false" >> $3sdcnf
echo "cache_credentials = false" >> $sdcnf
echo "" >> $sdcnf
echo "id_provider = ldap" >> $sdcnf
echo "auth_provider = krb5" >> $sdcnf
echo "chpass_provider = krb5" >> $sdcnf
echo "" >> $sdcnf
echo "ldap_uri = ldap://ldap.$newDom" >> $sdcnf
echo "ldap_search = dc=$dc1,dc=$dc2" >> $sdcnf
echo "ldap_sudo_search_base = ou=sudoers,dc=$dc1,dc=$dc2" >> $sdcnf
echo "ldap_tls_reqcert = never" >> $sdcnf
echo "" >> $sdcnf
echo "krb5_kdcip = kerberos.$newDom" >> $sdcnf
echo "krb5_realm = $newDomUp" >> $sdcnf
echo "krb5_changepw_principle = kadmin/changepw" >> $sdcnf
echo "krb5_auth_timeout = 15" >> $sdcnf
echo "krb5_renewable_lifetime = 5d" >> $sdcnf

# ensure proper permissions and start the sssd daemon
chmod 600 $sdcnf
service sssd restart

# Authenticate as the Kerberos administrative user
kinit $krbadmin/admin

# Kerberize ssh
mv $sshFile $sshFile.back.$tmstamp
touch $sshFile
echo "port 22" >> $sshFile
echo "protocol 2" >> $sshFile
echo "HostKey /etc/ssh/ssh_host_rsa_key" >> $sshFile
echo "HostKey /etc/ssh/ssh_host_dsa_key" >> $sshFile
echo "HostKey /etc/ssh/ssh_host_ecdsa_key" >> $sshFile
echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> $sshFile
echo "UsePrivilegeSeparation yes" >> $sshFile
echo "KeyRegenerationInterval 3600" >> $sshFile
echo "ServerKeyBits 1024" >> $sshFile
echo "SyslogFacility AUTH" >> $sshFile
echo "LogLevel INFO" >> $sshFile
echo "LoginGraceTime 30" >> $sshFile
echo "PermitRootLogin no" >> $sshFile
echo "StrictModes yes" >> $sshFile
echo "RSAAuthentication yes" >> $sshFile
echo "PubkeyAuthentication yes" >> $sshFile
echo "IgnoreRhosts yes" >> $sshFile
echo "RhostsRSAAuthentication no" >> $sshFile
echo "HostbasedAuthentication no" >> $sshFile
echo "PermitEmptyPasswords no" >> $sshFile # may not be necessary; need to check
echo "ChallengeResponseAuthentication yes" >> $sshFile
echo "PasswordAuthentication yes" >> $sshFile # may not be necessary; need to check
echo "GSSAPIAuthentication yes" >> $sshFile
echo "GSSAPICleanupCredentials yes" >> $sshFile
echo "X11Forwarding yes" >> $sshFile
echo "X11DisplayOffset 10" >> $sshFile
echo "PrintMotd no" >> $sshFile
echo "PrintLastLog yes" >> $sshFile
echo "TCPKeepAlive yes" >> $sshFile
echo "AcceptEnv LANG LC_*" >> $sshFile
echo "Subsystem sftp /usr/lib/openssh/sftp-server" >> $sshFile
echo "UsePAM yes" >> $sshFile

# Create kerberos principle for SSH service
kadmin.local -q "addprinc -randkey host/$srvrName.$newDom"
kadmin.local -q "ktadd host/$srvrName.$newDom"

# install NFSv4
aptitude install -y nfs-kernel-server nfs-common

# make required directories
mkdir /export
mkdir /export/home

# Add shared directory to fstab
sudo cp $fstb $fstb.back.$tmstamp
echo "/home    /export/home    none    bind    0    0" >> $fstb

# configure exports file
sudo cp $xprts $xprts.back.$tmstamp
echo "/export *(rw,fsid=0,crossmnt,insecure,async,no_subtree_check,sec=krb5p:krb5i:krb5)" >> $xprts
echo "/export/home *(rw,insecure,async,no_subtree_check,sec=krb5p:krb5i:krb5)" >> $xprts

# tell NFS to use Kerberos
mv $nfscmn $nfscmn.back.$tmstamp
touch $nfscmn
echo "NEED_STATD=" >> $nfscmn
echo "STATDOPTS=" >> $nfscmn
echo "NEED_GSSD=yes" >> $nfscmn

# adjust settings in nfs-kernel-server
mv $nksrv $nksrv.back.$tmstamp
touch $nksrv
echo "RPCNFSDCOUNT=8" >> $nksrv
echo "RPCNFSDPRIORITY=0" >> $nksrv
echo "RPCMOUNTDOPTS=\"--manage-gids\"" >> $nksrv
echo "NEED_SVCGSSD=\"yes\"" >> $nksrv
echo "RPCSVCGSSDOPTS=\"\"" >> $nksrv
echo "RPCNFSDOPTS=\"\"" >> $nksrv

# Add domain to idmapd.conf
mv $idmpd $idmpd.back.$tmstamp
touch $idmpd
echo "[General]" >> $idmpd
echo "" >> $idmpd
echo "Verbosity = 0" >> $idmpd
echo "Pipefs-Directory = /var/lib/nfs/rpc_pipefs" >> $idmpd
echo "Domain = $newDom" >> $idmpd
echo "" >> $idmpd
echo "[Mapping]" >> $idmpd
echo "" >> $idmpd
echo "Nobody-User = nobody" >> $idmpd
echo "Nobody-Group = nogroup" >> $idmpd

# Create Kerberos principles for NFS Server
kadmin.local -q "addprinc -randkey nfs/$srvrName.$newDom"
kadmin.local -q "ktadd nfs/$srvrName.$newDom"

# Restart NFS
service nfs-kernel-server restart