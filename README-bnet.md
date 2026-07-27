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

git repo with gitolite:

    # mkdir -pv /var/opt/backup/bnet/net_config_dc1_mikrotik
    # cd /var/opt/backup/bnet/net_config_dc1_mikrotik
    # git init -b main
    # git commit --allow-empty -m "root-commit"

    # ssh -p 2222 git@git1 create net/net_config_dc1_mikrotik
    # ssh -p 2222 git@git1 desc net/net_config_dc1_mikrotik "Mikrotik device config"
    # ssh -p 2222 git@git1 info -ld

    # git remote add git1 ssh://git@git1:2222/net/net_config_dc1_mikrotik
    # git push -u git1 main
