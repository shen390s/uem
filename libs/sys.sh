SYSLIB_DIR=$TOP/libs/syslib
. $SYSLIB_DIR/log.sh

SYSLIBS="env.sh hook.sh autolib.sh"
for _sl in $SYSLIBS; do
    _syslib=$SYSLIB_DIR/$_sl
    if [ -f $_syslib ]; then
	INFO "Loading syslib:%s" "$_syslib"
	. $_syslib
    else
	ERROR "syslib %s not found" "$_syslib"
    fi
done
