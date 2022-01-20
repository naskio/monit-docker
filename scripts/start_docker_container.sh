#!/bin/bash

for i in "$@"; do
  case $i in
  -d=* | --dir=*)
    DIR="${i#*=}"
    ;;
  *)
    # unknown option
    ;;
  esac
done
cd "$DIR" && docker-compose up -d
exit $?
