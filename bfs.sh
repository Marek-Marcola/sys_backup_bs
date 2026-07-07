#!/bin/bash

VERSION_BIN="260707"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="bs"
VERSION=0
STAGE_LIST=0
LINK=0
BACKUP=0
BACKUP_LIST=0
ROTATE=0
SIZE=0
PERM=0
SYNC=0
LIST=0
EVAL=0
HELP=0
VERB=0
QUIET=0

s=0

: ${A:=${SN%.sh}}
: ${APN:=$(echo $A|cut -d- -f2)}
: ${API:=$(echo $A|cut -d- -f3-)}
: ${LDIR:="/usr/local/bin/alias-bs"}
: ${COMM:=$(readlink -f ${BASH_SOURCE})}

while [ $# -gt 0 ]; do
  case $1 in
    --ver*|-ver*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    --stage|-stage)
      STAGE_LIST=1
      shift
      ;;
    -L)
      LINK=1
      shift
      ;;
    -B)
      BACKUP=1
      shift
      ;;
    -R)
      ROTATE=1
      shift
      ;;
    -s)
      SIZE=1
      shift
      ;;
    -p)
      PERM=1
      shift
      ;;
    -S)
      SYNC=1
      shift
      ;;
    -l)
      BACKUP_LIST=1
      [[ $BACKUP -eq 0 ]] && QUIET=1
      shift
      ;;
    -ls)
      LIST=1
      QUIET=1
      shift
      ;;
    -b)
      BACKUP=1
      BACKUP_LIST=1
      SIZE=1
      ROTATE=1
      EVAL=1
      shift
      ;;
    -bp)
      BACKUP=1
      BACKUP_LIST=1
      SIZE=1
      EVAL=1
      PERM=1
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -v)
      VERB=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    *)
      ARGS1+=("$1")
      shift
      ;;
  esac
done

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -ver                      # version"
  echo "$SN -inst [-x]                # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo "$SN -stage                    # stage list"
  echo ""
  echo "$SN -L [-x]                   # link show,exec"
  echo ""
  echo "$SN -l                        # list backup"
  echo "$SN -ls                       # list system"
  echo "$SN -s                        # backup size"
  echo "$SN -B [-x] [-v] [-p]         # backup,exec,verbose,permanent"
  echo "$SN -R [-x]                   # rotate,exec"
  echo "$SN -S [-x]                   # sync,exec"
  echo "$SN                           # info"
  echo ""
  echo "aliases:"
  echo "  -b  = -B -s -R -x -l"
  echo "  -bp = -B -s -p -x -l"
  echo ""
  echo "crontab:"
  echo "  15 23 * * * /usr/local/bin/bfs.sh -b >> /var/log/local/backup/bfs.log 2>&1"
  echo "  15 23 * * * /usr/local/bin/bfs.sh -b -S >> /var/log/local/backup/bfs.log 2>&1"
  exit 0
fi

#
# stage: CONFIG
#
: ${EDIR=/usr/local/etc/bfs.d}

for f in $(dirname $EDIR)/bfs.env $EDIR/$A; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

: ${BADIR:=/var/opt/backup/bfs}
: ${BVDIR:=/var/opt/bvault/bfs}
: ${ADIR:=$BADIR/$API}
: ${PDIR:=$BADIR/$API/perm}
: ${VDIR:=$BVDIR/$API}
: ${ETAG:=bfs.tag}
: ${BOPT:="--totals"}
: ${SOPT:="-azx -W -i --delete"}
: ${ANUM:=5}
: ${ARCH:=bfs-$API-$(date "+%y%m%d%H%M").tar}
: ${PATT:="bfs-*.tar.gz"}
: ${WDIR:=/}

if [ -z "$BDIR" ]; then
  BDIR=()
fi

if [ "$ETAG" != "" ]; then
  BOPT="$BOPT --exclude-tag-under=$ETAG"
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "bfs.env $VERSION_ENV"
  exit 0
fi

#
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-RSYNC"

  [[ $EVAL -ne 1 ]] && EVAL_OPT="-n" || EVAL_OPT=""

  if [ -f bfs.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/001010-backup/001010-000170_backup_scripts /pub/pkb/pb/playbooks/001010-backup/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT bfs.sh    $d/bfs.sh
        rsync -ai $EVAL_OPT bsync.sh  $d/bsync.sh
        rsync -ai $EVAL_OPT bnet.sh   $d/bnet.sh
        rsync -ai $EVAL_OPT bpgsql.sh $d/bpgsql.sh
        { set +ex; } 2>/dev/null
      fi
    done
  elif [ -f /pub/pkb/pb/playbooks/001010-backup/files/bfs.sh ]; then
    set -ex
    rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/001010-backup/files/bfs.sh    /usr/local/bin/
    rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/001010-backup/files/bsync.sh  /usr/local/bin/
    rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/001010-backup/files/bnet.sh   /usr/local/bin/
    rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/001010-backup/files/bpgsql.sh /usr/local/bin/
    { set +ex; } 2>/dev/null
  fi

  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: error: command not found: anpb"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb bs_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

  exit 0
fi

#
# stage: STAGE-LIST
#
if [ $STAGE_LIST -eq 1 ]; then
  cat $COMM | grep '^#' | grep 'stage:'
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  echo "efile =" $EFILE
  echo "App    = ${A:-[none]}"
  echo "APN    = ${APN:-[none]}"
  echo "API    = ${API:-[none]}"
  echo "ldir   = $LDIR"
  echo "adir  =" $ADIR
  echo "pdir  =" $PDIR
  echo "vdir  =" $VDIR
  echo "etag  =" $ETAG
  echo "bopt  =" $BOPT
  echo "sopt  =" $SOPT
  echo "anum  =" $ANUM
  echo "arch  =" $ARCH
  echo "patt  =" $PATT
  echo "wdir  =" $WDIR
  echo "bdir  =" ${BDIR[@]}
fi

#
# stage: LINK
#
if [ $LINK -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LINK"

  if [ ! -d $EDIR ]; then
    echo $ID: directory not found: $EDIR
    exit 1
  fi
  if [ ! -d $LDIR ]; then
    echo $ID: directory not found: $LDIR
    exit 1
  fi

  ls $EDIR/ | \
  while read E; do
    if [ -x $EDIR/$E ]; then
      continue
    fi

    LSRC=$COMM

    if [ ! -f $LDIR/$E ]; then
      if [ $EVAL -ne 0 ]; then
        set -ex
        ln -svr $LSRC $LDIR/$E
        { set +ex; } 2>/dev/null
      else
        echo "ln -svr $LSRC $LDIR/$E"
      fi
    else
      echo "# ln -svr $LSRC $LDIR/$E"
    fi
  done
fi

#
# stage: BACKUP
#
if [ $BACKUP -ne 0 -o $SIZE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP (EVAL=$EVAL,SIZE=$SIZE,PERM=$PERM)"

  if [ ! -d $WDIR ]; then
    echo $ID: no working directory: $WDIR
    exit 1
  fi

  set -ex
  cd $WDIR
  { set +ex; } 2>/dev/null

  EDIR=$(eval echo ${BDIR[@]})

  for d1 in $EDIR; do
    if [ -d $d1 ]; then
      d2=$(readlink -f $d1)
      d2=$(echo $d2 | sed "s|^$WDIR||")
      if [ "$d1" = "$d2" ]; then
        TDIR="$TDIR $d1"
      else
        TDIR="$TDIR $d1 $d2"
      fi
    fi
  done

  EDIR="$(echo $TDIR)"
  echo
  echo "edir =" $EDIR

  if [ $SIZE -ne 0 ]; then
    echo edir size:
    du -x -h -s $EDIR | sort -rh | awk '{s=$1; for(i=1; i<NF; i++) $i=$(i+1); NF-=1; printf "%8s %s\n",s,$0}'
  fi

  if [ $BACKUP -ne 0 -a $EVAL -ne 0 ]; then
    echo
    echo backup start: $(date "+%Y-%m-%d %H:%M:%S")
    T1=$(date +%s)

    if [ $PERM -eq 0 ]; then
      D=$ADIR
    else
      D=$PDIR
      if [ ! -d $D ]; then
        set -ex
        mkdir -v $D
        { set +ex; } 2>/dev/null
      fi
    fi

    if [ ! -d $D ]; then
      echo no archive directory: $D
      exit 1
    fi

    set -ex
    df -h $D
    { set +ex; } 2>/dev/null

    if [ $VERB -eq 0 ]; then
      set -x
      cd $WDIR
      tar cvf $D/$ARCH $BOPT $EDIR > /dev/null
      { set +x; } 2>/dev/null
    else
      set -x
      cd $WDIR
      tar cvf $D/$ARCH $BOPT $EDIR
      { set +x; } 2>/dev/null
    fi

    set -x
    gzip -fv $D/$ARCH
    { set +x; } 2>/dev/null

    T2=$(date +%s)
    T3=$(expr $T2 - $T1)
    echo backup end: $(date "+%Y-%m-%d %H:%M:%S"), time=$(date -d @$T3 -u +%H:%M:%S)
  fi
fi

#
# stage: ROTATE
#
if [ $ROTATE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ROTATE (EVAL=$EVAL)"

  echo protect:
  ls -1 $ADIR/$PATT|sort -r|head -$ANUM| \
  while read F; do
    ls -lh $F | sed 's/^/  /'
  done

  N1=$(expr $ANUM + 1)
  ND=$(ls -1 $ADIR/$PATT|sort -r|tail -n +$N1|wc -l)

  if [ $ND -gt 0 ]; then
    echo recycle:
    ls -1 $ADIR/$PATT|sort -r|tail -n +$N1| \
    while read F; do
      if [ $EVAL -eq 0 ]; then
        ls -lh $F | sed 's/^/  /'
      else
        set -ex
        rm -f $F
        { set +ex; } 2>/dev/null
      fi
    done
  fi
fi

#
# stage: SYNC
#
if [ $SYNC -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: SYNC (EVAL=$EVAL)"


  if [ $EVAL -eq 0 ]; then
    SOPT="$SOPT -n"
  fi

  set -x
  rsync $SOPT $ADIR/ $VDIR
  { set +x; } 2>/dev/null
fi

#
# stage: BACKUP-LIST
#
if [ $BACKUP_LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-LIST"

  if [ -d "$ADIR" ]; then
    set -x
    tree --noreport -F -h -C -L 1 -I perm $ADIR
    { set +x; } 2>/dev/null
  fi

  if [ -d "$PDIR" ]; then
    set -x
    tree --noreport -F -h -C -L 1 -I perm $PDIR
    { set +x; } 2>/dev/null
  fi
fi

#
# stage: LIST
#
if [ $LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LIST"

  if [ $LIST -eq 1 ]; then
    set -x
    tree --noreport -F -C /usr/local/backup
    { set +x; } 2>/dev/null
  fi
fi
