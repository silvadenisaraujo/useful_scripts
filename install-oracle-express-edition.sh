#!/bin/sh

#sources:
# http://meandmyubuntulinux.blogspot.com.br/2012/05/installing-oracle-11g-r2-express.html
# http://meandmyubuntulinux.blogspot.com.br/2012/06/trouble-shooting-oracle-11g.html

#install necessary packages
sudo apt-get install -y unzip alien libaio1 unixodbc

#Download the package
wget http://download.oracle.com/otn/linux/oracle11g/xe/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

#Unzip it
unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip

#go to unziped folder
cd Disk1/

#alien the package
sudo alien --scripts -d oracle-xe-11.2.0-1.0.x86_64.rpm

#Create /sbin/chkconfig
cat <<EOF >/sbin/chkconfig
#!/bin/bash
# Oracle 11gR2 XE installer chkconfig hack for Ubuntu
file=/etc/init.d/oracle-xe
if [[ ! `tail -n1 $file | grep INIT` ]]; then
echo >> $file
echo '### BEGIN INIT INFO' >> $file
echo '# Provides: OracleXE' >> $file
echo '# Required-Start: $remote_fs $syslog' >> $file
echo '# Required-Stop: $remote_fs $syslog' >> $file
echo '# Default-Start: 2 3 4 5' >> $file
echo '# Default-Stop: 0 1 6' >> $file
echo '# Short-Description: Oracle 11g Express Edition' >> $file
echo '### END INIT INFO' >> $file
fi
update-rc.d oracle-xe defaults 80 01
EOF

#change file permission
sudo chmod 755 /sbin/chkconfig

# Oracle 11g XE kernel parameters
cat <<EOF >/etc/sysctl.d/60-oracle.conf
fs.file-max=6815744
net.ipv4.ip_local_port_range=9000 65000
kernel.sem=250 32000 100 128
kernel.shmmax=536870912
EOF

#Load kernel parameters
sudo service procps start

#More some configurations
sudo ln -s /usr/bin/awk /bin/awk
mkdir /var/lock/subsys
touch /var/lock/subsys/listener

#Before installing now we will avoid the MEMORY TARGET error
sudo rm -rf /dev/shm
sudo mkdir /dev/shm
sudo mount -t tmpfs shmfs -o size=2048m /dev/shm


#This will ensure that every-time you start your system, you get a working Oracle environment.
cat <<EOF >/etc/rc2.d/S01shm_load
#!/bin/sh
case "$1" in
start) mkdir /var/lock/subsys 2>/dev/null
       touch /var/lock/subsys/listener
       rm /dev/shm 2>/dev/null
       mkdir /dev/shm 2>/dev/null
       mount -t tmpfs shmfs -o size=2048m /dev/shm ;;
*) echo error
   exit 1 ;;
esac
EOF

sudo chmod 755 /etc/rc2.d/S01shm_load

#Installing oracle
sudo dpkg --install oracle-xe_11.2.0-2_amd64.deb

#Configuring oracle
sudo /etc/init.d/oracle-xe configure

#Append new values on bashrc
echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> ~/.bashrc
echo 'export ORACLE_SID=XE' >> ~/.bashrc
echo 'export NLS_LANG=`$ORACLE_HOME/bin/nls_lang.sh`' >> ~/.bashrc
echo 'export ORACLE_BASE=/u01/app/oracle' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> ~/.bashrc

source ~/.bashrc

#Start service
sudo service oracle-xe start

#connecting
echo 'Testing the connection with Oracle!'
echo 'Please create a new user on sqlplus, with: '
echo 'create user [username] identified by [password];'
echo 'grant connect,resource to [username];'

sqlplus sys as sysdba
