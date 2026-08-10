#!/bin/bash

VERSION_BIN="260811"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="bs"
VERSION=0
STAGE_LIST=0
LINK=0
FSMOUNT=0
FSUMOUNT=0
BACKUP=0
BACKUP_SET=0
ESHOW=0
ESHOW_RE=""
EEDIT=0
EVAL=0
HELP=0
QUIET=0

BLOG=""

s=0

: ${A:=${SN%.sh}}
: ${APN:=$(echo $A|cut -d- -f2)}
: ${API:=$(echo $A|cut -d- -f3-)}
: ${LDIR:="/usr/local/bin/alias-bs"}
: ${EDIR:="/usr/local/etc/bsync.d"}
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
    -A)
      A="$2"
      APN=$(echo $A|cut -d- -f2)
      API=$(echo $A|cut -d- -f3-)
      ID="[$A]"
      shift; shift
      ;;
    -L)
      LINK=1
      shift
      ;;
    -s)
      ESHOW=1
      ESHOW_RE="$2"
      QUIET=1
      shift
      ;;
    -E)
      EEDIT=1
      shift
      ;;
    -M)
      FSMOUNT=1
      FSUMOUNT=1
      shift
      ;;
    -m)
      FSMOUNT=1
      shift
      ;;
    -u)
      FSUMOUNT=1
      shift
      ;;
    -B)
      BACKUP=1
      shift
      ;;
    -BS)
      BACKUP_SET=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && BSET="$2" && shift
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -bx)
      BACKUP=1
      EVAL=1
      shift
      ;;
    -bxm)
      BACKUP=1
      EVAL=1
      FSMOUNT=1
      FSUMOUNT=1
      shift
      ;;
    -bsx)
      BACKUP_SET=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && BSET="$2" && shift
      EVAL=1
      shift
      ;;
    -bsxm)
      BACKUP_SET=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && BSET="$2" && shift
      EVAL=1
      FSMOUNT=1
      FSUMOUNT=1
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
  echo "Backup filesystem (rsync)."
  echo ""
  echo "$SN -ver                      # version"
  echo "$SN -inst [-x]                # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo "$SN -stage                    # stage list"
  echo ""
  echo "$SN -L [-x]                   # link show,exec"
  echo ""
  echo "$SN -s [re]                   # env show"
  echo "$SN -E                        # env edit"
  echo ""
  echo "$SN -m                        # fs mount"
  echo "$SN -u                        # fs umount"
  echo "$SN -M                        # alias: -m -u"
  echo ""
  echo "$SN -B  [-x]                  # backup test,exec"
  echo "$SN -BS [list] [-x]           # backup set test,exec"
  echo ""
  echo "$SN -bx                       # alias: -B  -x"
  echo "$SN -bxm                      # alias: -B  -x -m -u"
  echo "$SN -bsx  [list]              # alias: -BS -x"
  echo "$SN -bsxm [list]              # alias: -BS -x -m -u"
  echo ""
  echo "$SN -l                        # list backup"
  echo "$SN                           # info"
  echo ""
  echo "env files: $(dirname $EDIR)/bsync.env $EDIR/\$A"
  exit 0
fi

#
# stage: CONFIG
#
for f in $(dirname $EDIR)/bsync.env $EDIR/$A; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

if [ -z "$OPTS" ]; then
  OPTS=( "-axz" "-W" "-i" )
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "bsync.env $VERSION_ENV"
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

  echo "efile  = ${EFILE:-[none]}"
  echo "App    = ${A:-[none]}"
  echo "APN    = ${APN:-[none]}"
  echo "API    = ${API:-[none]}"
  echo "ldir   = $LDIR"
  echo "FSDEV  = ${FSDEV:-[none]}"
  echo "FSDIR  = ${FSDIR:-[none]}"
  echo "BLOG   = ${BLOG:-[none]}"
  if [ -n "$BSET" ]; then
    echo "BSET   = $(echo $BSET|sed 's/ /\n/g'|sed '2,$s/^/         /')"
  else
    echo "BSET   = [none]"
  fi
  echo "OPTS   = "${OPTS[@]}""
  echo -n "SYNC   = "
  if [ -n "$SYNC" ]; then
  {
    for i in "${SYNC[@]}"; do
      echo "$i"
    done
  } | sed '2,$s/^/         /'
  else
    echo "[none]"
  fi
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
# stage: FS-MOUNT
#
if [ $FSMOUNT -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: FS-MOUNT"

  if [ -z "$FSDEV" -o -z "$FSDIR" ]; then
    echo "error: require fsdev,fsdir"
    exit 1
  fi

  if ! $(mountpoint -q $FSDIR); then
    if expr match $FSDEV LABEL: > /dev/null; then
      L=$(echo $FSDEV|awk -F: '{print $2}')
      L=$(blkid -o udev|grep ID_FS_LABEL=|awk -F= '{print $2}'|grep $L|head -1)

      if [ -n "$L" ]; then
        set -ex
        mount LABEL=$L $FSDIR
        df -h $FSDIR
        ls -l $FSDIR
        { set +ex; } 2>/dev/null
      else
        echo "error: unable to find disk label with re $FSDEV"
        exit 1
      fi
    else
      set -ex
      mount $FSDEV $FSDIR
      df -h $FSDIR
      { set +ex; } 2>/dev/null
    fi
  else
   set -ex
   df -h $FSDIR
   { set +ex; } 2>/dev/null
  fi
fi

#
# stage: BACKUP
#
if [ $BACKUP -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP (EVAL=$EVAL)"

  [[ $EVAL -ne 1 ]] && EVAL_OPT="-n" || EVAL_OPT=""

  if [ -n "$ROOT" ]; then
    if [ ! -d "$ROOT" ]; then
      echo "error: root dir not found: $ROOT"
      exit 1
    fi
  fi

  for i in "${SYNC[@]}"; do
    if [ "$i" = "" -o "$i" = "-" ]; then
      continue
    fi
    echo
    set -ex
    rsync "${OPTS[@]}" $EVAL_OPT $i 2>&1
    { set +ex; } 2>/dev/null
  done

  if [ -n "$BLOG" -a $EVAL -ne 0 ]; then
    if [ -d "$BLOG" ]; then
      BLOG=$BLOG/bsync.log
    fi
    echo
    echo blog: app=$A date=$(date "+%y%m%d_%H:%M") bsync_host=$(hostname) type=file | tee -a $BLOG
  else
    echo
    echo blog: app=$A date=$(date "+%y%m%d_%H:%M") bsync_host=$(hostname) type=echo
  fi

  if [ -d "$ROOT" ]; then
    echo
    set -ex
    ls -lh $ROOT
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: BACKUP-SET
#
if [ $BACKUP_SET -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-SET (EVAL=$EVAL)"

  if [ -z "$BSET" ]; then
    echo "error: require bset"
    exit 1
  fi

  [[ $EVAL  -ne 1 ]] && EVAL_OPT=""  || EVAL_OPT="-x"
  [[ $QUIET -ne 1 ]] && QUIET_OPT="" || QUIET_OPT="-q"

  BSET=$(echo $BSET|sed 's/,/ /g')

  for i in $BSET; do
    if [ $(type -t bs-bsync-$i) ]; then
      echo
      set -ex
      bs-bsync-$i -B $EVAL_OPT $QUIET_OPT
      { set +ex; } 2>/dev/null
    else
      echo
      echo "error: backup spec not found: bs-bsync-$i"
    fi
  done
fi

#
# stage: FS-UMOUNT
#
if [ $FSUMOUNT -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: FS-UMOUNT"

  if [ -z "$FSDIR" ]; then
    echo "error: require fsdir"
    exit 1
  fi

  if $(mountpoint -q $FSDIR); then
    set -ex
     df -h $FSDIR
    sync
    sync
    umount $FSDIR
    { set +ex; } 2>/dev/null
  else
    echo info: filesystem $FSDIR not mounted
  fi
fi

#
# stage: ENV-SHOW
#
if [ $ESHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (rexp: *$ESHOW_RE*)"

  if [ "$A" != "bsync" -a  "$ESHOW_RE" = "" ]; then
    if [ ! -f $EDIR/$A ]; then
      echo file not found: $EDIR/$A
    else
      set -ex
      cat $EDIR/$A
      { set +ex; } 2>/dev/null
    fi
  else
    for f in $EDIR/*$ESHOW_RE*; do
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
