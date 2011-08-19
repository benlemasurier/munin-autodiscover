#!/bin/bash
# Ben LeMasurier 2k11'
# automagically monitor new munin installations

MUNIN_PORT=4949
MUNIN_CONFIG="/usr/local/etc/munin/munin.conf"

NMAP=`(which nmap)`
TMP_FILE=`(mktemp -t munin.XXX)`

add_host ()
{
  echo -e "[$1]\naddress $1\nuse_node_name yes\n" >> $MUNIN_CONFIG
}

exists ()
{
  in_file=`cat $MUNIN_CONFIG | grep "$1" | wc -l`
  if [ $in_file -lt 1 ]; then
    echo 0;
    return;
  fi

  echo 1
}

parse ()
{
  hosts=`(cat $TMP_FILE | grep Ports | awk '{print $3}' | sed 's/[()]//g' | sed '/^$/d')`
  for host in ${hosts[@]}
  do
    host_exists=$(exists $host)
    if [ $host_exists -ne 1 ]; then
      $(add_host $host)
    fi
  done
}

scan ()
{
  $NMAP -T5 --open -p $MUNIN_PORT $1 -oG $TMP_FILE &> /dev/null
  parse;
}

check_config ()
{
  if [ ! -e $MUNIN_CONFIG ]; then
    echo "$MUNIN_CONFIG: file does not exist, exiting"
    exit 1;
  fi

  if [ ! -w $MUNIN_CONFIG ]; then
    echo "$MUNIN_CONFIG: permission denied, exiting"
    exit 1;
  fi
}

cleanup ()
{
  rm $TMP_FILE;
}

usage ()
{
  echo "usage: $0 <cidr>"
  exit 0
}

if [ $# -ne 1 ]; then
  usage;
fi

check_config;
scan $1;
cleanup;

exit 0
