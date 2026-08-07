backup scripts
==============

Backup scripts.

Deployment models: filesystem(tar,rsync), pgsql, net(mikrotik,hpsw,tplink)

Install
-------
Install:

    bfs.sh --inst -x
    -- or --
    bfs.sh --anpb -x
    -- or --
    cp -fv bfs.sh    /usr/local/bin
    cp -fv bsync.sh  /usr/local/bin
    cp -fv bpgsql.sh /usr/local/bin
    cp -fv bnet.sh   /usr/local/bin

    mkdir -pv /usr/local/etc/{bfs.d,bsync.d,bpgsql.d,bnet.d}
    mkdir -pv /usr/local/bin/alias-bs

Postinstall:

    # cat > /etc/profile.d/zlocal-backup.sh <<\EOF
    export PATH=/usr/local/bin/alias-bs:$PATH
    EOF

Verify:

    bfs.sh --ver

Help:

    bfs.sh --help
