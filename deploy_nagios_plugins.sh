# nagios plugins installation
sudo dnf install -y epel-release
sudo dnf install -y nrpe nagios-plugins-load nagios-plugins-disk \
  nagios-plugins-procs nagios-plugins-users nagios-plugins-swap \
  nagios-plugins-tcp nagios-plugins-ping nagios-plugins-http

# or sudo dnf install -y nrpe nagios-plugins-all

CFG=/etc/nagios/nrpe.cfg
sudo sed -i 's/^#\?\s*server_address=.*/server_address=0.0.0.0/' $CFG
sudo sed -i 's/^allowed_hosts=.*/allowed_hosts=127.0.0.1,192.168.56.9/' $CFG
sudo sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=0/' $CFG
sudo sed -i '/^command\[/d' $CFG
P=/usr/lib64/nagios/plugins
sudo tee -a $CFG >/dev/null <<EOF
command[check_users]=$P/check_users -w 5 -c 10
command[check_load]=$P/check_load -r -w 1.5,1.2,1.0 -c 3,2.5,2
command[check_disk]=$P/check_disk -w 20% -c 10% -p /
command[check_procs]=$P/check_procs -w 250 -c 400
command[check_swap]=$P/check_swap -w 20% -c 10%
command[check_pg_port]=$P/check_tcp -H 127.0.0.1 -p 5432
EOF

sudo systemctl enable --now nrpe
sudo systemctl restart nrpe

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.9" port port="5666" protocol="tcp" accept'
sudo firewall-cmd --reload


#########################################################
# some useful commands to solve problems with NRPE and Nagios plugins
# run on its own VM (not on Nagios server)
#######################################################
# on db vm, check if NRPE is listening on port 5666
#sudo ss -tlnp | grep -E '5432|5666'

# on nginx vm, check if NRPE has the check_nginx command
#grep check_nginx /etc/nagios/nrpe.cfg      # probably prints nothing
#echo 'command[check_nginx]=/usr/lib64/nagios/plugins/check_http -H 127.0.0.1 -p 80' | sudo tee -a /etc/nagios/nrpe.cfg
#sudo systemctl restart nrpe

# on tomcat vm, check if NRPE has the check_tomcat command
#grep check_tomcat /etc/nagios/nrpe.cfg      # probably prints nothing
#echo 'command[check_tomcat]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p 8080' | sudo tee -a /etc/nagios/nrpe.cfg
#sudo systemctl restart nrpe

# on rabbitmq vm, check if NRPE has the check_rabbitmq command
#grep check_rabbitmq /etc/nagios/nrpe.cfg      # probably prints nothing
#echo 'command[check_rabbitmq]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p 5672' | sudo tee -a /etc/nagios/nrpe.cfg
#sudo systemctl restart nrpe

# on memcached vm, check if NRPE has the check_memcached command
#grep include /etc/nagios/nrpe.cfg     # find the include dir, e.g. /etc/nrpe.d/
#echo 'command[check_memcached]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p 11211' | sudo tee /etc/nrpe.d/memcached.cfg
#sudo systemctl restart nrpe