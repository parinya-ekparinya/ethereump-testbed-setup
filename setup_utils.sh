#!/bin/bash

run_command()
{
  local CMD="$1"
  local NODES=( ${!2} )
  for node in ${NODES[@]}
  do
    rsh $node "$CMD" &
  done
  wait
}

