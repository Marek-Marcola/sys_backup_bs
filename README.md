backup scripts
==============

Backup scripts.

Deployment models: filesystem(tar,rsync), pgsql, net(mikrotik,hpsw,tplink)

Install
-------
Install:

    bfs.sh -inst -x
    -- or --
    bfs.sh -anpb -x
    -- or --
    cp -fv bfs.sh    /usr/local/bin
    cp -fv bsync.sh  /usr/local/bin
    cp -fv bpgsql.sh /usr/local/bin
    cp -fv bnet.sh   /usr/local/bin
    cp -fv zlocal-backup.sh /etc/profile.d

    mkdir -pv /usr/local/etc/{bfs.d,bsync.d,bpgsql.d,bnet.d}
    mkdir -pv /usr/local/bin/alias-bs

Verify:

    bs -ver

Help:

    bfs.sh    -h
    bsync.sh  -h
    bpgsql.sh -h
    bnet.sh   -h
