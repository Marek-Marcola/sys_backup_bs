backup scripts
==============

Backup scripts.

Deployment models: fs, sync, pgsql

Install
-------
Install:

    ./bfs.sh --install
    -- or --
    cp -fv bfs.sh /usr/local/backup/bin
    cp -fv bsync.sh /usr/local/backup/bin
    cp -fv bpgsql.sh /usr/local/backup/bin

    mkdir -pv /usr/local/backup/etc/{bfs.d,bsync.d,bpgsql.d}
    mkdir -pv /usr/local/backup/bin/alias-backup

Postinstall:

    # cat > /etc/profile.d/zlocal-backup.sh <<\EOF
    export PATH=/usr/local/backup/bin:/usr/local/backup/bin/alias-backup:$PATH
    EOF

Verify:

    bfs.sh --version

Help:

    bfs.sh --help
