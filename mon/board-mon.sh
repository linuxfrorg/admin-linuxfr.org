#!/bin/bash

# (C) 2011 LinuxFr.org
# Board monitoring script.

pidfile="/data/prod/linuxfr/board/board.pid"

if [ ! -f $pidfile ]; then
  echo "board-mon: error, pidfile $pidfile not present."
  exit 1
fi

kill -s 0 $(cat $pidfile) 2> /dev/null
if [ ! $? -eq 0 ]; then
  echo "board-mon: error, $pidfile present, but process not responding or not running."
  exit 1
fi

