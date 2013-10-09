#!/bin/bash

echo -e "[+]Local Linux Enumeration"
echo -e "\n"

#enter a single keyword that'll be used to search within *.conf and *.log files.
#read keyword
keyword="password"

echo -e "### SYSTEM ##############################################"

unameinfo=`uname -a 2>/dev/null`
if [ "$unameinfo" ]; then
  echo -e "Kernel information:\n$unameinfo"
  echo -e "\n"
else 
  :
fi

procver=`cat /proc/version 2>/dev/null`
if [ "$procver" ]; then
  echo -e "Kernel information continued:\n$procver"
  echo -e "\n"
else 
  :
fi

#search all *-release files for version info
release=`cat /etc/*-release 2>/dev/null`
if [ "$release" ]; then
  echo -e "Specific release information:\n$release"
  echo -e "\n"
else 
  :
fi

hostnamed=`hostname 2>/dev/null`
if [ "$hostnamed" ]; then
  echo -e "Hostname:\n$hostnamed"
  echo -e "\n"
else 
  :
fi

echo -e "### USER/GROUP ##########################################"

currusr=`id 2>/dev/null`
if [ "$currusr" ]; then
  echo -e "Current user/group info:\n$currusr"
  echo -e "\n"
else 
  :
fi

lastlogedonusrs=`lastlog |grep -v "Never" 2>/dev/null`
if [ "$lastlogedonusrs" ]; then
  echo -e "Users that have previously logged onto the system:\n$lastlogedonusrs"
  echo -e "\n"
else 
  :
fi

usrsinfo=`cat /etc/passwd | cut -d ":" -f 1,2,3,4 2>/dev/null`
if [ "$usrsinfo" ]; then
  echo -e "All users and uid/gid info - is the password stored here or /etc/shadow (represented by 'x'):\n$usrsinfo"
  echo -e "\n"
else 
  :
fi

#locate custom user accounts with some 'known default' uids
readpasswd=`grep -v "^#" /etc/passwd | awk -F: '$3 == 0 || $3 == 500 || $3 == 501 || $3 == 502 || $3 == 1000 || $3 == 1001 || $3 == 1002 || $3 == 2000 || $3 == 2001 || $3 == 2002 { print }'`
if [ "$readpasswd" ]; then
  echo -e "Sample entires from /etc/passwd (searching for uid values 0, 500, 501, 502, 1000, 1001, 1002, 2000, 2001, 2002):\n$readpasswd"
  echo -e "\n"
else 
  :
fi

readshadow=`cat /etc/shadow 2>/dev/null`
if [ "$readshadow" ]; then
  echo -e "We can read the shadow file!\n$readshadow"
  echo -e "\n"
else 
  :
fi

readmasterpasswd=`cat /etc/master.passwd 2>/dev/null`
if [ "$readmasterpasswd" ]; then
  echo -e "We can read the master.passwd file!\n$readmasterpasswd"
  echo -e "\n"
else 
  :
fi

#all root accounts (uid 0)
echo -e "Super user account(s):"; grep -v -E "^#" /etc/passwd | awk -F: '$3 == 0 { print $1}'
echo -e "\n"

#pull out vital sudoers info
sudoers=`cat /etc/sudoers 2>/dev/null`
if [ "$sudoers" ]; then
  echo -e "Sudoers configuration:"; cat /etc/sudoers 2>/dev/null | grep -A 1 "User priv"; cat /etc/sudoers | grep -A 1 "Allow"
  echo -e "\n"
else 
  :
fi

#can we sudo without supplying a password
sudoperms=`echo '' | sudo -S -l 2>/dev/null`
if [ "$sudoperms" ]; then
  echo -e "We can sudo without supplying a password!\n$sudoperms"
  echo -e "\n"
else 
  :
fi

#known 'good' breakout binaries
sudopwnage=`echo '' | sudo -S -l 2>/dev/null | grep -w 'nmap\|perl\|'awk'\|'find'\|'bash'\|'sh'\|'man'\|'more'\|'less'\|'vi'\|'vim'\|'nc'\|'netcat'\|python\|ruby\|lua\|irb' | xargs -r ls -la 2>/dev/null`
if [ "$sudopwnage" ]; then
  echo -e "Possible Sudo PWNAGE!\n$sudopwnage"
  echo -e "\n"
else 
  :
fi

rthmdir=`ls -ahl /root/ 2>/dev/null`
if [ "$rthmdir" ]; then
  echo -e "We can read root's home directory!\n$rthmdir"
  echo -e "\n"
else 
  :
fi

homedirperms=`ls -ahl /home/ 2>/dev/null`
if [ "$homedirperms" ]; then
  echo -e "Are permissions on /home directories lax:\n$homedirperms"
  echo -e "\n"
else 
  :
fi

echo -e "### ENVIRONMENTAL #######################################"

pathinfo=`echo $PATH 2>/dev/null`
if [ "$pathinfo" ]; then
  echo -e "Path information:\n$pathinfo"
  echo -e "\n"
else 
  :
fi

echo -e "### JOBS/TASKS ##########################################"

cronjobs=`ls -la /etc/cron* 2>/dev/null`
if [ "$cronjobs" ]; then
  echo -e "Cron jobs:\n$cronjobs"
  echo -e "\n"
else 
  :
fi

cronjobwwperms=`find /etc/cron* -perm -0002 -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
if [ "$cronjobwwperms" ]; then
  echo -e "World-writable cron jobs and file contents:\n$cronjobwwperms"
  echo -e "\n"
else 
  :
fi

crontab=`cat /etc/crontab 2>/dev/null`
if [ "$crontab" ]; then
  echo -e "Crontab contents:\n$crontab"
  echo -e "\n"
else 
  :
fi

crontabvar=`ls -la /var/spool/cron/crontabs 2>/dev/null`
if [ "$crontabvar" ]; then
  echo -e "Anything interesting in /var/spool/cron/crontabs:\n$crontabvar"
  echo -e "\n"
else 
  :
fi

anacronjobs=`ls -la /etc/anacrontab 2>/dev/null; cat /etc/anacrontab 2>/dev/null`
if [ "$anacronjobs" ]; then
  echo -e "Anacron jobs and associated file permissions:\n$anacronjobs"
  echo -e "\n"
else 
  :
fi

anacrontab=`ls -la /var/spool/anacron 2>/dev/null`
if [ "$anacrontab" ]; then
  echo -e "When were jobs last executed (/var/spool/anacron contents):\n$anacrontab"
  echo -e "\n"
else 
  :
fi

#pull out account names from /etc/passwd and see if any users have associated cronjobs (priv command)
cronother=`cat /etc/passwd | cut -d ":" -f 1 | xargs -n1 crontab -l -u 2>/dev/null`
if [ "$cronother" ]; then
  echo -e "Jobs held by all users:\n$cronother"
  echo -e "\n"
else 
  :
fi

echo -e "### NETWORKING  ##########################################"

nicinfo=`/sbin/ifconfig -a 2>/dev/null | grep -A 1 "eth"`
if [ "$nicinfo" ]; then
  echo -e "Network & ip info:\n$nicinfo"
  echo -e "\n"
else 
  :
fi

nsinfo=`cat /etc/resolv.conf 2>/dev/null | grep "nameserver"`
if [ "$nsinfo" ]; then
  echo -e "Nameserver(s):\n$nsinfo"
  echo -e "\n"
else 
  :
fi

defroute=`route 2>/dev/null | grep default`
if [ "$defroute" ]; then
  echo -e "Default route:\n$defroute"
  echo -e "\n"
else 
  :
fi

tcpservs=`netstat -antp 2>/dev/null`
if [ "$tcpservs" ]; then
  echo -e "Listening tcp:\n$tcpservs"
  echo -e "\n"
else 
  :
fi

udpservs=`netstat -anup 2>/dev/null`
if [ "$udpservs" ]; then
  echo -e "Listening udp:\n$udpservs"
  echo -e "\n"
else 
  :
fi

echo -e "### SERVICES #############################################"

psaux=`ps aux 2>/dev/null`
if [ "$psaux" ]; then
  echo -e "Running processes:\n$psaux"
  echo -e "\n"
else 
  :
fi

#lookup process binary path and permissisons
procperm=`ps aux | awk '{print $11}'|xargs -r ls -la 2>/dev/null |awk '!x[$0]++'`
if [ "$procperm" ]; then
  echo -e "Process binaries & associated permissions (from above list):\n$procperm"
  echo -e "\n"
else 
  :
fi

inetdread=`cat /etc/inetd.conf 2>/dev/null`
if [ "$inetdread" ]; then
  echo -e "Contents of /etc/inetd.conf:\n$inetdread"
  echo -e "\n"
else 
  :
fi

#very 'rough' command to extract associated binaries from inetd.conf & show permisisons of each
inetdbinperms=`cat /etc/inetd.conf 2>/dev/null | awk '{print $7}' |xargs -r ls -la 2>/dev/null`
if [ "$inetdbinperms" ]; then
  echo -e "The related inetd binary permissions:\n$inetdbinperms" 
  echo -e "\n"
else 
  :
fi


xinetdread=`cat /etc/xinetd.conf 2>/dev/null`
if [ "$xinetdread" ]; then
  echo -e "Contents of /etc/xinetd.conf:\n$xinetdread"
  echo -e "\n"
else 
  :
fi

xinetdincd=`cat /etc/xinetd.conf 2>/dev/null |grep "/etc/xinetd.d" 2>/dev/null`
if [ "$xinetdincd" ]; then
  echo -e "/etc/xinetd.d is included in /etc/xinetd.conf - associated binary permissions are listed below:"; ls -la /etc/xinetd.d 2>/dev/null
  echo -e "\n"
else 
  :
fi

#very 'rough' command to extract associated binaries from xinetd.conf & show permisisons of each
xinetdbinperms=`cat /etc/xinetd.conf 2>/dev/null | awk '{print $7}' |xargs -r ls -la 2>/dev/null`
if [ "$xinetdbinperms" ]; then
  echo -e "The related xinetd binary permissions:\n$xinetdbinperms"; 
  echo -e "\n"
else 
  :
fi

initdread=`ls -la /etc/init.d 2>/dev/null`
if [ "$initdread" ]; then
  echo -e "/etc/init.d/ binary permissions:\n$initdread"
  echo -e "\n"
else 
  :
fi  

rcdread=`ls -la /etc/rc.d/init.d 2>/dev/null`
if [ "$rcdread" ]; then
  echo -e "/etc/rc.d/init.d binary permissions:\n$rcdread"
  echo -e "\n"
else 
  :
fi

usrrcdread=`ls -la /usr/local/etc/rc.d 2>/dev/null`
if [ "$usrrcdread" ]; then
  echo -e "/usr/local/etc/rc.d binary permissions:\n$usrrcdread"
  echo -e "\n"
else 
  :
fi

echo -e "### SOFTWARE #############################################"

sudover=`sudo -V | grep "Sudo version" 2>/dev/null`
if [ "$sudover" ]; then
  echo -e "Sudo version:\n$sudover"
  echo -e "\n"
else 
  :
fi

mysqlver=`mysql --version 2>/dev/null`
if [ "$mysqlver" ]; then
  echo -e "MYSQL version:\n$mysqlver"
  echo -e "\n"
else 
  :
fi

mysqlconnect=`mysqladmin -uroot -proot version 2>/dev/null`
if [ "$mysqlconnect" ]; then
  echo -e "We can connect to the local MYSQL service with default root/root credentials!\n$mysqlconnect"
  echo -e "\n"
else 
  :
fi

postgver=`psql -V 2>/dev/null`
if [ "$postgver" ]; then
  echo -e "Postgres version:\n$postgver"
  echo -e "\n"
else 
  :
fi

postcon1=`psql -U postgres template0 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon1" ]; then
  echo -e "We can connect to Postgres DB 'template0' as user 'postgres' with no password!:\n$postcon1"
  echo -e "\n"
else 
  :
fi

postcon11=`psql -U postgres template1 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon11" ]; then
  echo -e "We can connect to Postgres DB 'template1' as user 'postgres' with no password!:\n$postcon11"
  echo -e "\n"
else 
  :
fi

postcon2=`psql -U pgsql template0 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon2" ]; then
  echo -e "We can connect to Postgres DB 'template0' as user 'psql' with no password!:\n$postcon2"
  echo -e "\n"
else 
  :
fi

postcon22=`psql -U pgsql template1 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon22" ]; then
  echo -e "We can connect to Postgres DB 'template1' as user 'psql' with no password!:\n$postcon22"
  echo -e "\n"
else 
  :
fi

apachever=`apache2 -v 2>/dev/null; httpd -v 2>/dev/null`
if [ "$apachever" ]; then
  echo -e "Apache version:\n$apachever"
  echo -e "\n"
else 
  :
fi

echo -e "### INTERESTING FILES ####################################"
echo -e "Useful file locations:"      ;which nc 2>/dev/null; which netcat 2>/dev/null; which wget 2>/dev/null; which nmap 2>/dev/null; which gcc 2>/dev/null
echo -e "\n"
echo -e "Can we read/write sensitive files:"	;ls -la /etc/passwd 2>/dev/null; ls -la /etc/group 2>/dev/null; ls -la /etc/profile 2>/dev/null; ls -la /etc/shadow 2>/dev/null; ls -la /etc/master.passwd 2>/dev/null
echo -e "\n"

findsuid=`find / -perm -4000 -type f 2>/dev/null`
if [ "$findsuid" ]; then
  echo -e "SUID files:\n$findsuid"
  echo -e "\n"
else 
  :
fi

#list of 'interesting' suid files - feel free to make additions
intsuid=`find / -perm -4000 -type f 2>/dev/null | grep -w 'nmap\|perl\|'awk'\|'find'\|'bash'\|'sh'\|'man'\|'more'\|'less'\|'vi'\|'vim'\|'nc'\|'netcat'\|python\|ruby\|lua\|irb\|pl' | xargs -r ls -la`
if [ "$intsuid" ]; then
  echo -e "Possibly interesting SUID files:\n$intsuid"
  echo -e "\n"
else 
  :
fi

wwsuid=`find / -perm -4007 -type f 2>/dev/null`
if [ "$wwsuid" ]; then
  echo -e "World-writable SUID files:\n$wwsuid"
  echo -e "\n"
else 
  :
fi

wwsuidrt=`find / -uid 0 -perm -4007 -type f 2>/dev/null`
if [ "$wwsuidrt" ]; then
  echo -e "World-writable SUID files owned by root:\n$wwsuidrt"
  echo -e "\n"
else 
  :
fi

findguid=`find / -perm -2000 -type f 2>/dev/null`
if [ "$findguid" ]; then
  echo -e "GUID files:\n$findguid"
  echo -e "\n"
else 
  :
fi

#list of 'interesting' guid files - feel free to make additions
intguid=`find / -perm -2000 -type f 2>/dev/null | grep -w 'nmap\|perl\|'awk'\|'find'\|'bash'\|'sh'\|'man'\|'more'\|'less'\|'vi'\|'vim'\|'nc'\|'netcat'\|python\|ruby\|lua\|irb\|pl' | xargs -r ls -la`
if [ "$intguid" ]; then
  echo -e "Possibly interesting GUID files:\n$intguid"
  echo -e "\n"
else 
  :
fi

wwguid=`find / -perm -2007 -type f 2>/dev/null`
if [ "$wwguid" ]; then
  echo -e "World-writable GUID files:\n$wwguid"
  echo -e "\n"
else 
  :
fi

wwguidrt=`find / -uid 0 -perm -2007 -type f 2>/dev/null`
if [ "$wwguidrt" ]; then
  echo -e "AWorld-writable GUID files owned by root:\n$wwguidrt"
  echo -e "\n"
else 
  :
fi

#list all world-writable files excluding /proc
wwfiles=`find / ! -path "*/proc/*" -perm -2 -type f -print 2>/dev/null`
if [ "$wwfiles" ]; then
  echo -e "World-writable files (excluding /proc):\n$wwfiles"
  echo -e "\n"
else 
  :
fi

usrplan=`find /home -iname *.plan -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
if [ "$usrplan" ]; then
  echo -e "Plan file permissions and contents:\n$usrplan"
  echo -e "\n"
else 
  :
fi

rhostsusr=`find /home -iname *.rhosts -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
if [ "$rhostsusr" ]; then
  echo -e "rhost config file(s) and contents:\n$rhostsusr"
  echo -e "\n"
else 
  :
fi

rhostssys=`find /etc -iname hosts.equiv -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
if [ "$rhostssys" ]; then
  echo -e "Hosts.equiv binary details & contents: \n$rhostssys"
  echo -e "\n"
  else 
  :
fi

nfsexports=`ls -la /etc/exports 2>/dev/null; cat /etc/exports 2>/dev/null`
if [ "$nfsexports" ]; then
  echo -e "NFS config details: \n$nfsexports"
  echo -e "\n"
  else 
  :
fi

#use supplied keyword and cat *.conf files for potentional matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ];then
  echo -e "Can't search *.conf files as no keyword was entered\n"
  else
    confkey=`find / -maxdepth 4 -name *.conf -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$confkey" ]; then
      echo -e "Find keyword ($keyword) in .conf files (recursive 4 levels - output format filepath:identified line number where keyword appears):\n$confkey"
      echo -e "\n"
     else 
	echo -e "Find keyword ($keyword) in .conf files (recursive 4 levels):"
	echo -e "'$keyword' not found in any .conf files"
	echo -e "\n"
    fi
fi

#use supplied keyword and cat *.log files for potentional matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ];then
  echo -e "Can't search *.log files as no keyword was entered\n"
  else
    logkey=`find / -maxdepth 2 -name *.log -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$logkey" ]; then
      echo -e "Find keyword ($keyword) in .log files (recursive 2 levels - output format filepath:identified line number where keyword appears):\n$logkey"
      echo -e "\n"
     else 
	echo -e "Find keyword ($keyword) in .log files (recursive 2 levels):"
	echo -e "'$keyword' not found in any .log files"
	echo -e "\n"
    fi
fi

allconf=`find /etc/ -maxdepth 1 -name *.conf -type f -exec ls -la {} \; 2>/dev/null`
if [ "$allconf" ]; then
  echo -e "All *.conf files in /etc (recursive 1 level):\n$allconf" 
  echo -e "\n"
else 
  :
fi

usrhist=`ls -la ~/.*_history 2>/dev/null`
if [ "$usrhist" ]; then
  echo -e "Current user's history files:\n$usrhist" 
  echo -e "\n"
else 
  :
fi

roothist=`ls -la /root/.*_history 2>/dev/null`
if [ "$roothist" ]; then
  echo -e "Root's history files are accessible!\n$roothist"
  echo -e "\n"
else 
  :
fi

readmail=`ls -la /var/mail 2>/dev/null`
if [ "$readmail" ]; then
  echo -e "Any interesting mail in /var/mail:\n$readmail"
  echo -e "\n"
else 
  :
fi

readmailroot=`head /var/mail/root 2>/dev/null`
if [ "$readmailroot" ]; then
  echo -e "We can read /var/mail/root! (snippet below)\n$readmailroot"
  echo -e "\n"
else 
  :
fi

echo -e "### SCAN COMPLETE ####################################"