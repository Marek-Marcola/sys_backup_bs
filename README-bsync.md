backup script bsync
===================

Config
------
bsync env:

    # cat /usr/local/etc/bsync.env
    OPTS=( --archive --one-file-system --compress --whole-file --itemize-changes --delete )
    OPTS=( -axz -W -i --delete )

    FSDEV=LABEL:disk
    FSDIR=/vol/mnt

    # cat /usr/local/etc/bsync.d/bs-bsync-d-k2
    HN=k2

    ROOT=$FSDIR/$APN/$HN
    BLOG=$ROOT

    SYNC=(
     "root@$HN:/etc             $ROOT"
     "root@$HN:/home            $ROOT"
     "root@$HN:/root            $ROOT --exclude /root/.vagrant.d --exclude /root/.apptainer"
     "root@$HN:/usr/local/etc   $ROOT/usr/local"
     "root@$HN:/usr/local/bin   $ROOT/usr/local"
     "root@$HN:/var/opt/backup/ $ROOT/var/opt/backup"
     -
     "root@$HN:/scm/            $ROOT/scm"
     "root@$HN:/pub/            $ROOT/pub"
     "root@$HN:/nethome/        $ROOT/nethome"
     -
     "root@$HN:/vol/v01/vms/    $ROOT/vol/v01/vms --exclude *.qcow2"
    )
