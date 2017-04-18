#!/bin/bash

# Get dirs ready
mkdir -p /opt/logs
mkdir -p /opt/app
mkdir -p /opt/webs

# jdk and symbolic link
cd /opt
echo "Extracts jdk"
for j in ./packages/jdk*.tar.gz ; do
    tar zxf $j 
done
# Make the latest version default
_jdk=`find -type d -name "jdk1.*"|sort -V|tail -1`
echo "$_jdk is default jdk"
ln -sf $_jdk ./jdk

# Maven
cd /opt
echo "Extracts maven"
for m in ./packages/apache-maven*.tar.gz ; do
    tar zxf $m
done
# Make the latest version default
_maven=`find -type d -name apache-maven*|sort -V|tail -1`
echo "$_maven is default maven"
ln -sf $_maven ./maven

# Configure tomcats app/webs
cd /opt/app
echo "Extracts tomcat*.zip"
for tzip in ../packages/apache-tomcat-*.zip ; do
    unzip -q $tzip
done
echo "Extracts tomcat*.tar.gz"
for ttar in ../packages/apache-tomcat-*.tar.gz ; do
    tar zxf $ttar
done

_setenv='
JAVA_OPTS="-server -Xms1024m -Xmx1024m -XX:+UseG1GC"
CATALINA_OPTS=" -Djava.security.egd=file:/dev/urandom"
UMASK="0022"
CATALINA_OUT=/dev/null'

for tm in apache-tomcat-*/ ; do 
    cd $tm
    pwd
    rm ./bin/*.bat -f
    chmod +x ./bin/*.sh
    echo "$_setenv" > ./bin/setenv.sh
    rm ./webapps/* -rf
    sed -i 's/%s %b/%s %b %D %S %{X-Forwarded-For}i %{Referer}i/g' ./conf/server.xml
    ls -l
    _webdir="/opt/webs/app-`echo $tm|sed 's/apache-tomcat-//g'`"
    mkdir -p $_webdir
    mv ./conf $_webdir
    mv ./logs $_webdir
    mv ./temp $_webdir
    mv ./webapps $_webdir
    mv ./work $_webdir
    cd ..
done

# Make the latest version default
_tomcat=`find -type d -name "apache-tomcat-*"|sort -V|tail -1`
ln -sf $_tomcat ./tomcat

# Get nginx ready
yum install nginx -y
systemctl enable nginx

# firewalld 
if ! systemctl status firewalld|egrep '(could not be found|disabled;)'; then
    firewall-cmd --add-port 80/tcp --permanent
    firewall-cmd --add-port 443/tcp --permanent
    firewall-cmd --add-port 8009/tcp --permanent
    firewall-cmd --add-port 8080/tcp --permanent
    firewall-cmd --add-port 8081/tcp --permanent
    firewall-cmd --add-port 8082/tcp --permanent
    firewall-cmd --add-port 8083/tcp --permanent
    firewall-cmd --reload
fi

