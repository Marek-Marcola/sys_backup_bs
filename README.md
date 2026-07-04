backup scripts
==============

Backup scripts.

Deployment models: fs, sync, pgsql, net(mikrotik,hpsw)

Install
-------
Install:

    ./bfs.sh --install
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

    bfs.sh --version

Help:

    bfs.sh --help
