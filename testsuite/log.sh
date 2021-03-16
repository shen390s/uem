#! /bin/sh
# -*- mode:shell-script

_appdir=`dirname $0`
TOP=`cd $_appdir/.. && pwd`
export TOP

. $TOP/libs/sys.sh

DEBUG=INFO

log_init

ERROR "fire!!!"
WARN  "Save %s!" "Mad Dog"
INFO  "Come here"
DEBUG3 "Thanks"

DEBUG=DEBUG3

log_init

ERROR "fire again!"
INFO "%s! Go away!" "Mike"
DEBUG3 "Saved"

DEBUG=TRACE

log_init
DEBUG "Something wrong"

set +x
DEBUG=fuck

log_init

DEBUG "Hello"
