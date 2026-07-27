backup script bfs
=================

Config
------
bfs env:

    # cat /usr/local/etc/bfs.d/bs-bfs-sys
    BDIR=( etc root "usr/local/{bin,etc}" "opt/local/{bin,etc}" )
    API=$(hostname -s)

bfs aliases:

    # bfs.sh -L -x

crontab:

    # crontab -l
    15 23 * * * /usr/local/bin/alias-bs/bs-bfs-sys -b >> /var/log/local/bs/bs-bfs-sys.log 2>&1
