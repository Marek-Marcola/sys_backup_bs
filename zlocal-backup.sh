export PATH=/usr/local/bin/alias-bs:$PATH

bf() {
  local desc="@@backup file with suffix@@"

  if [ "$1" = "-h" -o "$1" = "-help" -o "$1" = "--help" -o "$1" = "" ]; then
    echo "usage: ${FUNCNAME[0]} file"
  elif [ ! -f "$1" ]; then
    echo "unable to backup: $1"
  else
    cp -pv $1 ${1}.b$(date +%y%m%d)
  fi
}

bs() {
  local desc="@@backup scripts info@@"
  local d

  if [ "$1" = "-h" -o "$1" = "-help" -o "$1" = "--help" ]; then
    echo "${FUNCNAME[0]} -V|-ver                   # version"
    echo "${FUNCNAME[0]} -inst [host_list]    [-x] # install with rsync"
    echo "${FUNCNAME[0]} -anpb [host_pattern] [-x] # install with ansible"
    echo "${FUNCNAME[0]}                           # backup list"
  elif [ "$1" = "-V" -o "$1" = "-ver" -o "$1" = "--ver" ]; then
  {
    bfs.sh -ver
    bsync.sh -ver
    bpgsql.sh -ver
    bnet.sh -ver
  } | column -t
  elif [ "$1" = "-inst" ]; then
    bfs.sh $@
  elif [ "$1" = "-anpb" ]; then
    bfs.sh $@
  else
    for d in /usr/local/etc/{bfs.d,bsync.d,bpgsql.d,bnet.d}; do
      if [ -d "$d" ]; then
        tree --noreport -F -C -L 1 $d
      fi
    done
  fi
}
