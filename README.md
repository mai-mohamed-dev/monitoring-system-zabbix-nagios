# Monitoring System: Zabbix + Nagios
Enterprise Infrastructure Monitoring with Nagios and Zabbix

## Files

| File | Run on | Purpose |
|---|---|---|
| `Vagrantfile` | host | Defines the VMs |
| `monitor_provision.sh` | Zabbix VM | Installs Zabbix server, MariaDB, Apache, frontend, agent |
| `auto/setup_autoregistration.py` | Zabbix VM | Creates the auto-registration action (metadata `linux-server`) |
| `nagios_provision.sh` | Nagios VM | Builds Nagios Core, plugins, `check_nrpe` |
| `deploy_zabbix_agents.sh` | every target | Installs and configures the Zabbix agent |
| `deploy_nagios_plugins.sh` | every target | Installs NRPE and plugins, opens port 5666 for the Nagios VM |
| `zabbix_agent_db_only.sh` |	db VM only | Zabbix agent 2 with the PostgreSQL plugin for the PostgreSQL by Zabbix agent 2 template |


## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Unit nrpe.service does not exist` | Package did not install | Enable CRB, install `nrpe`, or build from source |
| `NRPE: Command 'x' not defined` | No `command[x]` on the target | Add it on the **target**, restart `nrpe` |
| `No route to host` on 5666 | Firewall rule or wrong IP | Check the rich rule for the Nagios IP and `allowed_hosts` |
| `Connection refused` on a service port | The service is not running on the target | Start the service, check `ss -tlnp` |
| `HTTP 502 Bad Gateway` (nginx) | Backend unreachable | Open the backend port in firewalld, check the upstream address |

