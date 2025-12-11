#!/bin/bash

VERSION_BIN="202512110061"

SN="${0##*/}"
ID="[$SN]"

INSTALL=0
VERSION=0
LINK=0
BACKUP_ONLINE=0
BACKUP_ONLINE_LIST=0
BACKUP_BASE=0
BACKUP_BASE_DIR=""
ROTATE=0
EVAL=0
PERM=0
SYNC=0
ELIST=0
ESHOW=0
ESHOW_REXP=""
EEDIT=0
HELP=0
VERB=0
QUIET=0

declare -a OPTS2

s=0

: ${A:=${SN%.sh}}
: ${APN:=$(echo $A|cut -d- -f2)}
: ${API:=$(echo $A|cut -d- -f3-)}
: ${BDIR:="/usr/local/backup/bin/alias-backup"}
: ${COMM:=$(readlink -f ${BASH_SOURCE})}

if [ $# -eq 0 ]; then
  if [ "$A" = "bpgsql" ]; then
    ELIST=1
    QUIET=1
  fi
fi

while [ $# -gt 0 ]; do
  case $1 in
    --inst*|-inst*)
      INSTALL=1
      shift
      ;;
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    -A)
      A="$2"
      shift; shift
      ;;
    -B)
      BACKUP_ONLINE=1
      shift
      ;;
    -bb)
      BACKUP_BASE=1
      BACKUP_BASE_DIR="$2"
      shift; shift
      ;;
    -L)
      LINK=1
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -R)
      ROTATE=1
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
      BACKUP_ONLINE_LIST=1
      [[ $BACKUP_ONLINE -eq 0 ]] && QUIET=1
      shift
      ;;
    -ls)
      ELIST=1
      QUIET=1
      shift
      ;;
    -s*)
      [[ "$1" != "-s" ]] && ESHOW_REXP=${1:2}
      ESHOW=1
      QUIET=1
      shift
      ;;
    -E)
      EEDIT=1
      shift
      ;;
    -b)
      BACKUP_ONLINE=1
      BACKUP_ONLINE_LIST=1
      ROTATE=1
      EVAL=1
      shift
      ;;
    -bp)
      BACKUP_ONLINE=1
      BACKUP_ONLINE_LIST=1
      EVAL=1
      PERM=1
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
      OPTS2+=("$1")
      shift
      ;;
  esac
done

if [ $HELP -eq 1 ]; then
  echo "$SN -install      # install"
  echo "$SN -version      # version"
  echo ""
  echo "$SN -L [-x]       # link show,run"
  echo ""
  echo "$SN -ls           # env list"
  echo "$SN -s[rexp]      # env show"
  echo "$SN -E            # env edit"
  echo ""
  echo "$SN -B [-p] [-x]  # online_backup,permanent,exec"
  echo "$SN -bb dir [-x]  # base_backup with replication_setup,exec"
  echo ""
  echo "$SN -R [-x]       # rotate_backup,exec"
  echo "$SN -S [-x]       # sync_backup,exec"
  echo "$SN -l            # list backup"
  echo "$SN               # info"
  echo ""
  echo "opts:"
  echo "  -A  - backup specification"
  echo ""
  echo "alias:"
  echo "  -b  = -B -R -x -l"
  echo "  -bp = -B -p -x -l"
  echo ""
  echo "crontab:"
  echo "  15 23 * * * /usr/local/backup/bin/bpgsql.sh -A bs-apn-api -b    >> /var/log/local/backup/bs-apn-api.log 2>&1"
  echo "  15 23 * * * /usr/local/backup/bin/bpgsql.sh -A bs-apn-api -b -S >> /var/log/local/backup/bs-apn-api.log 2>&1"
  exit 0
fi

#
# stage: CONFIG
#
: ${EDIR=/usr/local/backup/etc/bpgsql.d}

if [ -f $(dirname $EDIR)/bpgsql.env ]; then
  . $(dirname $EDIR)/bpgsql.env
  EFILE=$(dirname $EDIR)/bpgsql.env
fi

if [ -f $EDIR/$A ]; then
  . $EDIR/$A
  EFILE="$EFILE $EDIR/$A"
fi

: ${BADIR=/var/backup/bpgsql}
: ${BVDIR=/var/bvault/bpgsql}
: ${ADIR=$BADIR/$A}
: ${PDIR=$BADIR/$A/perm}
: ${VDIR=$BVDIR/$A}
: ${PATT="$PGCL-*/base.tar"}
: ${ANUM=5}

: ${SBOPTS="-azx -W -i --delete"}
: ${OBOPTS="-P -v -X stream -Ft"}
: ${BBOPTS="-P -v -X stream -Fp -R"}

: ${PGUID=26}
: ${PGGID=26}

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "bsystem.env $VERSION_ENV"
  exit 0
fi

#
# stage: INSTALL
#
if [ $INSTALL -eq 1 ]; then
  if [ -f bpgsql.sh ]; then
    for d in /usr/local/backup/bin /pub/pkb/kb/data/001010-backup/001010-000170_script_bpgsql /pub/pkb/pb/playbooks/001010-backup/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai bpgsql.sh $d/bpgsql.sh
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  echo "efile  = ${EFILE:-[none]}"
  echo "App    = ${A:-[none]}"
  echo "APN    = ${APN:-[none]}"
  echo "API    = ${API:-[none]}"
  echo "bbdir  = ${BACKUP_BASE_DIR:-[none]}"
  echo "adir   = ${ADIR:-[none]}"
  echo "pdir   = ${PDIR:-[none]}"
  echo "vdir   = ${VDIR:-[none]}"
  echo "pgopts = ${PGOPTS[@]:-[none]}"
  echo "obopts = ${OBOPTS:-[none]}"
  echo "bbopts = ${BBOPTS:-[none]}"
  echo "sbopts = ${SBOPTS:-[none]}"
  echo "pguid  = ${PGUID:-[none]}"
  echo "pggid  = ${PGGID:-[none]}"
  echo "patt   = ${PATT:-[none]}"
  echo "anum   = $ANUM"
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
  if [ ! -d $BDIR ]; then
    echo $ID: directory not found: $BDIR
    exit 1
  fi

  ls $EDIR/ | \
  while read E; do
    if [ -x $EDIR/$E ]; then
      continue
    fi

    LSRC=$COMM

    if [ ! -f $BDIR/$E ]; then
      if [ $EVAL -ne 0 ]; then
        set -ex
        ln -svr $LSRC $BDIR/$E
        { set +ex; } 2>/dev/null
      else
        echo "ln -svr $LSRC $BDIR/$E"
      fi
    else
      echo "# ln -svr $LSRC $BDIR/$E"
    fi
  done
fi

#
# stage: BACKUP-ONLINE
#
if [ $BACKUP_ONLINE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-ONLINE (EVAL=$EVAL,PERM=$PERM)"

  if [ "$A" = "bpgsql" ]; then
    echo "$ID: error: require app"
    exit 1
  fi

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

  echo online backup start: $(date "+%Y-%m-%d %H:%M:%S")
  T1=$(date +%s)

  TDIR=$PGCL-$(date "+%Y%m%d%H%M")

  if [ $EVAL -ne 0 ]; then
    (
    set -x

    mkdir -pv $D/$TDIR
    pg_basebackup -D $D/$TDIR "${PGOPTS[@]}" $OBOPTS 2>&1
    ls -lh $D/$TDIR

    { set +x; } 2>/dev/null
    ) 2>&1 | stdbuf -o0 sed 's/^/  /' | GREP_COLORS="mt=01;35" grep --color=auto ".*"
  else
    (
    echo mkdir -pv $D/$TDIR
    echo pg_basebackup -D $D/$TDIR "${PGOPTS[@]}" $OBOPTS
    echo ls -lh $D/$TDIR
    ) 2>&1 | stdbuf -o0 sed 's/^/  /' | GREP_COLORS="mt=01;35" grep --color=auto ".*"
  fi

  T2=$(date +%s)
  T3=$(expr $T2 - $T1)
  echo online backup end: $(date "+%Y-%m-%d %H:%M:%S"), time=$(date -d @$T3 -u +%H:%M:%S)
fi

#
# stage: BACKUP-BASE
#
if [ $BACKUP_BASE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-BASE (EVAL=$EVAL)"

  if [ "$A" = "bpgsql" ]; then
    echo "$ID: error: require app"
    exit 1
  fi

  if [ $EVAL -ne 0 ]; then
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
      echo directory not found: $BACKUP_BASE_DIR
      exit 1
    fi
  fi

  echo base backup start: $(date "+%Y-%m-%d %H:%M:%S")
  T1=$(date +%s)

  if [ $EVAL -ne 0 ]; then
    (
    set -x
    setpriv --reuid=$PGUID --regid=$PGGID --clear-groups \
      pg_basebackup -D $BACKUP_BASE_DIR "${PGOPTS[@]}" $BBOPTS
    ls -lh $BACKUP_BASE_DIR
    { set +x; } 2>/dev/null
    ) 2>&1 | stdbuf -o0 sed 's/^/  /' | GREP_COLORS="mt=01;35" grep --color=auto ".*"
  else
    (
    echo setpriv --reuid=$PGUID --regid=$PGGID --clear-groups \
      pg_basebackup -D $BACKUP_BASE_DIR "${PGOPTS[@]}" $BBOPTS
    echo ls -lh $BACKUP_BASE_DIR
    ) 2>&1 | stdbuf -o0 sed 's/^/  /' | GREP_COLORS="mt=01;35" grep --color=auto ".*"
  fi

  T2=$(date +%s)
  T3=$(expr $T2 - $T1)
  echo base backup end: $(date "+%Y-%m-%d %H:%M:%S"), time=$(date -d @$T3 -u +%H:%M:%S)

  echo
  echo streaming replication setup:

  if [ $EVAL -ne 0 ]; then
    set -x
    ls -l $BACKUP_BASE_DIR/standby.signal
    cat $BACKUP_BASE_DIR/postgresql.auto.conf
    { set +x; } 2>/dev/null
  else
    echo ls -l $BACKUP_BASE_DIR/standby.signal
    echo cat $BACKUP_BASE_DIR/postgresql.auto.conf
  fi
fi

#
# stage: ROTATE
#
if [ $ROTATE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ROTATE (EVAL=$EVAL)"

  if [ "$A" = "" ]; then
    echo "$ID: error: require app"
    exit 1
  fi

  echo protect:
  ls -1d $ADIR/$PATT 2>/dev/null|sort -r|head -$ANUM| \
  while read P; do
    D=$(dirname $P)
    ls -ld $D | sed 's/^/  /'
  done

  N1=$(expr $ANUM + 1)
  ND=$(ls -1d $ADIR/$PATT 2>/dev/null|sort -r|tail -n +$N1|wc -l)

  if [ $ND -gt 0 ]; then
    echo recycle:
    ls -1d $ADIR/$PATT|sort -r|tail -n +$N1| \
    while read P; do
      D=$(dirname $P)
      if [ $EVAL -eq 0 ]; then
        ls -ld $D | sed 's/^/  /'
      else
        ls -ld $D | sed 's/^/  /'
        (
        set -x
        rm -f $D/base.tar
        rm -f $D/pg_wal.tar
        rm -f $D/backup_manifest
        rmdir $D
        { set +x; } 2>/dev/null
        ) 2>&1 | stdbuf -o0 sed 's/^/  /' | GREP_COLORS="mt=01;35" grep --color=auto ".*"
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

  if [ "$A" = "bpgsql" ]; then
    echo "$ID: error: require app"
    exit 1
  fi

  if [ $EVAL -eq 0 ]; then
    SBOPTS="$SBOPTS -n"
  fi

  set -x
  rsync $SBOPTS $ADIR/ $VDIR
  { set +x; } 2>/dev/null
fi

#
# stage: BACKUP-ONLINE-LIST
#
if [ $BACKUP_ONLINE_LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-ONLINE-LIST"

  if [ "$A" != "bpgsql" ]; then
    set -x
    tree --noreport -F -h -C -L 2 -l -I perm $ADIR
    { set +x; } 2>/dev/null
    if [ -d $PDIR ]; then
      tree --noreport -F -h -C -L 2 -l -I perm $PDIR
    fi
  else
    set -x
    tree --noreport -F -h -C -l $BADIR
    { set +x; } 2>/dev/null
  fi
fi

#
# stage: ENV-LIST
#
if [ $ELIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-LIST"

  set -x
  ls -log $EDIR
  { set +x; } 2>/dev/null
fi

#
# stage: ENV-SHOW
#
if [ $ESHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (rexp: *$ESHOW_REXP*)"

  if [ "$A" != "bpgsql" -a  "$ESHOW_REXP" = "" ]; then
    if [ ! -f $EDIR/$A ]; then
      echo file not found: $EDIR/$A
    else
      set -ex
      cat $EDIR/$A
      { set +ex; } 2>/dev/null
    fi
  else
    for f in $EDIR/*$ESHOW_REXP*; do
      if [ -f $f ]; then
        set -ex
        cat $f  2>&1
        { set +ex; } 2>/dev/null
        echo
      fi 
    done
  fi
fi

#
# stage: ENV-EDIT
#
if [ $EEDIT -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-EDIT"

  if [ ! -d $EDIR ]; then
    echo directory not found: $EDIR
  else
    if [ "$EDITOR" != "" ]; then
      set -ex
      $EDITOR $EDIR/$A
      { set +ex; } 2>/dev/null
    else
      set -ex
      vi $EDIR/$A
      { set +ex; } 2>/dev/null
    fi
  fi
fi
