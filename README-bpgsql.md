backup script bpgsql
====================

Config
------
bpgsql env:

    # cat /usr/local/etc/bpgsql.d/b-bpgsql-admin
    PGCL=admin
    PGOPTS=( -d "host=a511 port=5401 user=dbrep password=dbpass" )

bpgsql aliases:

    # bpgsql.sh -L -x

cman bpgsql controller:

    # cat /usr/local/etc/cman.d/bc-bpgsql-admin
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

cman aliases:

    # cm -L -x
