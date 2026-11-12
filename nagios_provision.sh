# Avoid SELinux issues
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config


sudo dnf install -y gcc glibc glibc-common perl httpd php wget gd gd-devel s-nail postfix 
sudo dnf install -y openssl-devel
sudo dnf update -y

cd /tmp
sudo wget --output-document="nagioscore.tar.gz" $(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
sudo tar xzf nagioscore.tar.gz

cd /tmp/nagios-*
sudo ./configure
sudo make all
sudo make install-groups-users
sudo usermod -a -G nagios apache

sudo make install
sudo make install-daemoninit
sudo systemctl enable httpd.service
sudo make install-commandmode
sudo make install-config
sudo make install-webconf

sudo systemctl enable --now firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
#password:nagiosadmin
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

sudo systemctl start httpd.service

sudo systemctl start nagios.service


#############################################################
# Nagios Plugins installation
###########################################################
sudo dnf install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release httpd
sudo dnf config-manager --set-enabled crb
sudo dnf install -y perl-Net-SNMP

cd /tmp
sudo wget --output-document="nagios-plugins.tar.gz" $(wget -q -O - https://api.github.com/repos/nagios-plugins/nagios-plugins/releases/latest  | grep '"browser_download_url":' | grep -o 'https://[^"]*')
sudo tar zxf nagios-plugins.tar.gz

cd /tmp/nagios-plugins-*
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install

sudo systemctl enable --now httpd
sudo systemctl enable --now nagios


sudo dnf install -y nrpe nagios-plugins-nrpe

#add the following lines in /usr/local/nagios/etc/objects/commands.cfg
sudo tee -a /usr/local/nagios/etc/objects/commands.cfg >/dev/null <<'EOF'
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
EOF

sudo mkdir -p /usr/local/nagios/etc/servers
sudo chown nagios:nagios /usr/local/nagios/etc/servers
sudo grep -n "cfg_dir" /usr/local/nagios/etc/nagios.cfg
echo 'cfg_dir=/usr/local/nagios/etc/servers' | sudo tee -a /usr/local/nagios/etc/nagios.cfg

sudo grep USER1 /usr/local/nagios/etc/resource.cfg
sudo dnf install -y gcc make openssl-devel
cd /tmp
sudo wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.0/nrpe-4.1.0.tar.gz
sudo tar xzf nrpe-4.1.0.tar.gz && cd nrpe-4.1.0
sudo ./configure
sudo make check_nrpe
sudo make install-plugin


#sudo vim /usr/local/nagios/etc/servers/hosts.cfg
# define host {
#    use                 linux-server
#    host_name           db
#    address             192.168.56.15
#}
#define service {
#    use                 generic-service
#    host_name           db
#    service_description Disk Usage
#    check_command       check_nrpe!check_disk
#}

#define service {
#    use                 generic-service
#    host_name           db
#    service_description CPU Load
#    check_command       check_nrpe!check_load
#}
sudo tee /usr/local/nagios/etc/servers/db.cfg >/dev/null <<'EOF'
define host {
    use         linux-server
    host_name   db
    address     192.168.56.15
}
define service {
    use generic-service
    host_name db
    service_description Disk Usage
    check_command check_nrpe!check_disk
}
define service {
    use generic-service
    host_name db
    service_description CPU Load
    check_command check_nrpe!check_load
}
define service {
    use generic-service
    host_name db
    service_description Swap
    check_command check_nrpe!check_swap
}
define service {
    use generic-service
    host_name db
    service_description PostgreSQL Port
    check_command check_nrpe!check_pg_port
}
EOF
sudo tee /usr/local/nagios/etc/servers/memcache.cfg >/dev/null <<'EOF'
define host {
    use         linux-server
    host_name   memcache
    address     192.168.56.14
}
define service {
    use generic-service
    host_name memcache
    service_description Disk Usage
    check_command check_nrpe!check_disk
}
define service {
    use generic-service
    host_name memcache
    service_description CPU Load
    check_command check_nrpe!check_load
}
define service {
    use generic-service
    host_name memcache
    service_description Memcached Port
    check_command check_nrpe!check_memcached
}
EOF
sudo tee /usr/local/nagios/etc/servers/rabbitmq.cfg >/dev/null <<'EOF'
define host {
    use         linux-server
    host_name   rabbitmq
    address     192.168.56.13
}
define service {
    use generic-service
    host_name rabbitmq
    service_description Disk Usage
    check_command check_nrpe!check_disk
}
define service {
    use generic-service
    host_name rabbitmq
    service_description CPU Load
    check_command check_nrpe!check_load
}
define service {
    use generic-service
    host_name rabbitmq
    service_description RabbitMQ Service
    check_command check_nrpe!check_rabbitmq
}
EOF
sudo tee /usr/local/nagios/etc/servers/tomcat.cfg >/dev/null <<'EOF'
define host {
    use         linux-server
    host_name   tomcat
    address     192.168.56.12
}
define service {
    use generic-service
    host_name tomcat
    service_description Disk Usage
    check_command check_nrpe!check_disk
}
define service {
    use generic-service
    host_name tomcat
    service_description CPU Load
    check_command check_nrpe!check_load
}
define service {
    use generic-service
    host_name tomcat
    service_description Tomcat Port
    check_command check_nrpe!check_tomcat
}
EOF
sudo tee /usr/local/nagios/etc/servers/nginx.cfg >/dev/null <<'EOF'
define host {
    use         linux-server
    host_name   nginx
    address     192.168.56.11
}
define service {
    use generic-service
    host_name nginx
    service_description Disk Usage
    check_command check_nrpe!check_disk
}
define service {
    use generic-service
    host_name nginx
    service_description CPU Load
    check_command check_nrpe!check_load
}
define service {
    use generic-service
    host_name nginx
    service_description Nginx HTTP
    check_command check_nrpe!check_nginx
}
EOF

sudo chown -R nagios:nagios /usr/local/nagios/etc/servers/

sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

sudo systemctl restart nagios

