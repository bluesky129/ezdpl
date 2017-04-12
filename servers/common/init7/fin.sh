#!/bin/bash

# Install epel
if ! grep enabled=1 /etc/yum.repos.d/epel* ;then
  if grep " 6." /etc/redhat-release ; then
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
  fi
  if grep " 7." /etc/redhat-release ; then
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  fi
fi

killall -9 yum
yum clean all
yum -y install telnet net-tools dos2unix man nmap yum-utils vim wget zip unzip ntpdate tree gcc iptraf tcpdump bind-utils lsof sysstat dstat iftop htop openssl openssl-devel openssh bash mailx lynx &&  echo "Packages installed..."

ln -sf /usr/sbin/iptraf-ng  /usr/sbin/iptraf
ln -sf /var/log/iptraf-ng   /var/log/iptraf

# Install rpms
cd /opt/packages
for x in *.rpm ; do 
    rpm -ivh $x 
done

# Download & extract lynis (security auditing tool)
cd /opt/ && rm ./lynis -rf 2>/dev/null
wget https://cisofy.com/download/lynis/ -O /dev/shm/lynix.html
_lynis=`cat /dev/shm/lynix.html |sed 's/ /\n/g'|grep "cisofy.com/files"|grep -v asc|awk -F'"' '{print $2}'`
echo $_lynis
wget $_lynis
tar zxvf ./lynis-*.tar.gz -C /opt/ > /dev/null && echo "lynis installed in /opt/lynis"

# vim auto indent(Hit <F9> for proper pasting)
# q command replaced with :q
# Q command replaced with :q!
_vimrc="set nocompatible
set shiftwidth=4
filetype plugin indent on
set pastetoggle=<F9>
nnoremap q :q
nnoremap Q :q!
"
echo "$_vimrc" > /root/.vimrc

#firewalld
systemctl enable firewalld
firewall-cmd --add-port 22/tcp --permanent
firewall-cmd --add-port 2222/tcp --permanent
firewall-cmd --reload

#selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# crontab 
if [[ ! -f /var/spool/cron/root ]]; then
    touch /var/spool/cron/root
fi
_cron="*/10 * * * * /usr/local/bin/ban_ssh.sh
*/10 * * * * /usr/sbin/ntpdate 0.centos.pool.ntp.org 1.centos.pool.ntp.org 2.centos.pool.ntp.org 3.centos.pool.ntp.org"
sed -i /"ban_ssh"/d /var/spool/cron/root
sed -i /"ntpdate"/d /var/spool/cron/root
echo "$_cron" >> /var/spool/cron/root
chmod 600 /var/spool/cron/root


