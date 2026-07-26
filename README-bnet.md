backup script bnet
==================

Config
------
bnet env:

    # cat /usr/local/etc/bnet.d/bs-bnet-dc1-mikrotik 
    DEVS=(
      s111 s112 s113
    )
    WDIR=/var/opt/backup/bnet
    REPO=net_config_dc1_mikrotik

git repo:

    # mkdir -pv /var/opt/backup/bnet/net_config_dc1_mikrotik
    # cd /var/opt/backup/bnet/net_config_dc1_mikrotik
    # git init
    # git commit --allow-empty -m "root-commit"
