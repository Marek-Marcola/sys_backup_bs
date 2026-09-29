backup script bpgsql
====================

Config
------
bpgsql controller:

    # cm bpgsql
    [cman.sh]: stage: APP-IMAGE (re: *bpgsql*)
    App              Image                             Ver
    bc-bpgsql-admin  scr.dc.local:5443/is/pgsql:17.11  17.11

    # bc-bpgsql-admin -s
    [bc-bpgsql-admin]: stage: ENV-SHOW (re: **)
    + cat /usr/local/etc/cman.d/bc-bpgsql-admin
    : ${V:=17.11}
    : ${I:=scr.dc.local:5443/is/pgsql:$V}
    BADIR=/var/opt/backup/$APN
    OPTS=(
    --volume /etc/profile.d/zlocal-backup.sh:/etc/profile.d/zlocal-backup.sh:ro
    --volume /usr/local/etc:/usr/local/etc:ro
    --volume /usr/local/bin:/usr/local/bin:ro
    --volume $BADIR/b-$APN-$API:$BADIR/b-$APN-$API
    )
    INIT=(
     "install -m 755 -o root -g root -v -d $BADIR/b-$APN-$API"
    )
    DOCS="
      $A -r
      $A -r -- -l
      $A -r -v /tmp/stage:/tmp/stage -- -bb /tmp/stage/${V%.*} -x
    "
    : ${ARGS:="bash -l b-$APN-$API"}
    : ${ARGS2:="-b"}
