#!/bin/bash
for i in "$@"; do
  case $i in
  -c=* | --container=*)
    CONTAINER_NAME="${i#*=}"
    ;;
  *)
    # unknown option
    ;;
  esac
done

docker top "$CONTAINER_NAME"
exit $?
