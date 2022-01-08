#!/bin/bash
# systemctl --quiet is-active docker # --quiet to disable output message
systemctl is-active docker
exit $?
