#!/bin/bash

VERSION_BIN="260716"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="bs"
VERSION=0
STAGE_LIST=0
LINK=0
BACKUP_MIKROTIK=0
BACKUP_HPSW=0
GIT=0
ESHOW=0
ESHOW_RE=""
EEDIT=0
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
    -x)
      EVAL=1
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
    -A)
      A="$2"
      APN=$(echo $A|cut -d- -f2)
      API=$(echo $A|cut -d- -f3-)
      ID="[$A]"
      shift; shift
      ;;
    -Bm)
      BACKUP_MIKROTIK=1
      shift
      ;;
    -Bh)
      BACKUP_HPSW=1
      shift
      ;;
    -G)
      GIT=1
      shift
      ;;
    -bmg)
      BACKUP_MIKROTIK=1
      GIT=1
      EVAL=1
      shift
      ;;
    -bhg)
      BACKUP_HPSW=1
      GIT=1
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

if [ $HELP -eq 1 ]; then
  echo "Backup network device."
  echo ""
  echo "$SN -ver                      # version"
  echo "$SN -inst [-x]                # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo "$SN -stage                    # stage list"
  echo ""
  echo "$SN -L [-x]                   # link show,run"
  echo ""
  echo "$SN -s [re]                   # env show"
  echo "$SN -E                        # env edit"
  echo ""
  echo "$SN -Bm [-x]                  # backup mikrotik,exec"
  echo "$SN -Bh [-x]                  # backup hpsw,exec"
  echo ""
  echo "$SN -G  [-x]                  # git commit/push,exec"
  echo ""
  echo "$SN -bmg                      # alias: -Bm -G -x"
  echo "$SN -bhg                      # alias: -Bh -G -x"
  echo ""
  echo "$SN                           # info"
  exit 0
fi

#
# stage: CONFIG
#
: ${EDIR=/usr/local/etc/bnet.d}

if [ -f $(dirname $EDIR)/bnet.env ]; then
  . $(dirname $EDIR)/bsw.env
  EFILE=$(dirname $EDIR)/bnet.env
fi

if [ -f $EDIR/$A ]; then
  . $EDIR/$A
  EFILE="$EFILE $EDIR/$A"
fi

: ${WDIR=/}

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

  echo "efile  = ${EFILE:-[none]}"
  echo "App    = ${A:-[none]}"
  echo "APN    = ${APN:-[none]}"
  echo "API    = ${API:-[none]}"
  echo "ldir   = $LDIR"
  echo "devs   = ${DEVS[*]}"
  echo "wdir   = $WDIR"
  echo "repo   = $REPO"
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
# stage: BACKUP-MIKROTIK
#
if [ $BACKUP_MIKROTIK -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-MIKROTIK (EVAL=$EVAL)"

  set -ex
  cd $WDIR/$REPO
  { set +ex; } 2>/dev/null

  echo
  echo mikrotik backup start: $(date "+%Y-%m-%d %H:%M:%S")
  T1=$(date +%s)

  for d in ${DEVS[*]}; do
    echo

    # export terse
    f=${d}_export_terse.txt
    echo | xargs -L1 -t ssh $d /export terse | \
      sed 's/\r//' | \
      awk '{sub(/^ +/, "", $0); if (sub(/\\$/,"")) printf "%s", $0; else print $0}' | \
      sed "s/^#.* by RouterOS/# RouterOS/" > tmp.txt
    if [ -s tmp.txt ]; then
      if [ -f $f ]; then
        if ! diff tmp.txt $f; then
          [ $EVAL -ne 0 ] && mv -fv tmp.txt $f || echo "# mv -fv tmp.txt $f"
        fi
      else
        [ $EVAL -ne 0 ] && mv -v tmp.txt $f || echo "# mv -fv tmp.txt $f"
      fi
    fi

    # export compact
    f=${d}_export_compact.txt
    echo | xargs -L1 -t ssh $d /export compact | \
      sed 's/\r//' | \
      awk '{sub(/^ +/, "", $0); if (sub(/\\$/,"")) printf "%s", $0; else print $0}' | \
      sed "s/^#.* by RouterOS/# RouterOS/" > tmp.txt
    if [ -s tmp.txt ]; then
      if [ -f $f ]; then
        if ! diff tmp.txt $f; then
          [ $EVAL -ne 0 ] && mv -fv tmp.txt $f || echo "# mv -fv tmp.txt $f"
        fi
      else
        [ $EVAL -ne 0 ] && mv -fv tmp.txt $f || echo "# mv -fv tmp.txt $f"
      fi
    fi

    # export verbose
    f=${d}_export_verbose.txt
    echo | xargs -L1 -t ssh $d /export verbose | \
      sed 's/\r//' | \
      sed "s/^#.* by RouterOS/# RouterOS/" > tmp.txt
    if [ -s tmp.txt ]; then
      if [ -f $f ]; then
        if ! diff tmp.txt $f; then
          [ $EVAL -ne 0 ] && mv -v tmp.txt $f || echo "# mv -fv tmp.txt $f"
        fi
      else
        [ $EVAL -ne 0 ] && mv -v tmp.txt $f || echo "# mv -fv tmp.txt $f"
      fi
    fi
  done

  echo
  T2=$(date +%s)
  T3=$(expr $T2 - $T1)
  echo mikrotik backup end: $(date "+%Y-%m-%d %H:%M:%S"), time=$(date -d @$T3 -u +%H:%M:%S)

  rm -f tmp.txt
fi

#
# stage: GIT
#
if [ $GIT -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: GIT (EVAL=$EVAL)"

  set -ex
  cd $WDIR/$REPO
  { set +ex; } 2>/dev/null

  if [ ! -d .git ]; then
    echo "$ID: not git repo"
    exit 1
  fi

  set -ex
  git add -uv .
  { set +ex; } 2>/dev/null

  if ! git diff --staged --quiet; then
    C=b$(date +%y%m%d%H%M)
    set -ex
    git commit -m $C
    git remote -v | grep push | cut -f1 | xargs -L1 -tr git push
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: ENV-SHOW
#
if [ $ESHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (rexp: *$ESHOW_RE*)"

  if [ "$A" != "bnet" -a  "$ESHOW_RE" = "" ]; then
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
