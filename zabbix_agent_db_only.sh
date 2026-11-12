# for deploying zabbix agents on DB VM
set -e

SERVER_IP="192.168.56.10"       # Zabbix server
NAME=$(hostname -s)            # unique name of this VM in Zabbix
METADATA="linux-server"        # must match the auto-registration action condition
CONF="/etc/zabbix/zabbix_agent2.conf"

case "$NAME" in localhost|"") echo "Set a real hostname first"; exit 1 ;; esac

# 1. Check if Zabbix Agent 7.0 is already installed and running the correct version
CURRENT_VERSION=$(zabbix_agent2 -V 2>/dev/null | head -n1 | grep -oP '7\.0\.\d+' || echo "")


if [ -z "$CURRENT_VERSION" ]; then
    echo "[INFO] Zabbix Agent 7.0 not found. Installing..."
    
    # Ensure EPEL release is present and exclude zabbix from it (with proper sudo)
    sudo dnf install -y epel-release
    [ -f /etc/yum.repos.d/epel.repo ] && ! sudo grep -q '^excludepkgs=zabbix' /etc/yum.repos.d/epel.repo \
      && sudo sed -i '/^\[epel\]/a excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo

    # Install Zabbix 7.0 repository and agent package cleanly
    sudo dnf install -y https://repo.zabbix.com/zabbix/7.0/centos/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
    sudo dnf clean all
    sudo dnf makecache
    sudo dnf install -y zabbix-agent2 zabbix-agent2-plugin-postgresql
else
    echo "[INFO] Zabbix Agent 7.0 is already installed ($CURRENT_VERSION). Skipping installation."
fi

# Verify agent version matches 7.0
zabbix_agent2 -V | head -n1 | grep -q '7\.0\.' || { echo "[ERROR] agent is not 7.0"; zabbix_agent2 -V | head -n1; exit 1; }

# 2. Configuration (safely updates or replaces existing values using sudo)
sudo sed -i -E '/^(Server|ServerActive|Hostname|HostnameItem|HostMetadata)=/d' "$CONF"
printf 'Server=%s\nServerActive=%s\nHostname=%s\nHostMetadata=%s\n' \
  "$SERVER_IP" "$SERVER_IP" "$NAME" "$METADATA" | sudo tee -a "$CONF" >/dev/null

# 3. Start now and on every boot
sudo systemctl enable zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo firewall-cmd --permanent --add-port=10050/tcp && sudo firewall-cmd --reload
echo "Agent active: Hostname=$NAME HostMetadata=$METADATA Server=$SERVER_IP"


# for PostgreSQL monitoring, create a user with monitoring privileges on db vm only 
sudo -u postgres psql -c "CREATE USER zbx_monitor WITH PASSWORD 'ChangeMe_Str0ng'; GRANT pg_monitor TO zbx_monitor;"
# let the zabbix user read logs 
sudo setfacl -m u:zabbix:rx /var/lib/pgsql/data/log
sudo setfacl -m u:zabbix:r /var/log/secure


# Go to Data collection > Hosts > db > Templates and link PostgreSQL by Zabbix agent 2 and Linux by Zabbix agent.
# On the host, set the macros {$PG.URI}=tcp://localhost:5432, {$PG.USER}=zbx_monitor, {$PG.PASSWORD}=ChangeMe_Str0ng.
# Add two items of type Zabbix agent (active), type of information Log, with these keys:
# logrt["/var/lib/pgsql/data/log/postgresql-.*\.log","ERROR|FATAL|deadlock",,,skip]
# log[/var/log/secure,"Failed password",,,skip]
# Add triggers on those items with str()/nodata() conditions.