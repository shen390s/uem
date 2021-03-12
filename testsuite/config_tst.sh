#!/bin/sh
# -*- mode:shell-script
_appdir=`dirname $0`
TOP=`cd $_appdir/.. && pwd`
export TOP

if [ -f $TOP/libs/sys.sh ]; then
    . $TOP/libs/sys.sh
fi

if [ -f $TOP/libs/config.sh ]; then
    . $TOP/libs/config.sh
fi

on_feature() {
    echo
    echo "action: $1"
    echo "feature: $2"
    shift 2
    while [ $# -gt 0 ]; do
	echo "\toption: $1"
	shift
    done
}

dummy_action() {
    echo
    echo "dummy: $@"
}


features="+pkg(+nix +pkgsrc -brew -macport) +emacs(+native -x11 +macos) -anaconda +rust +rtc"

add_hook process_feature_hook dummy_action
add_hook process_feature_hook on_feature

echo "parsing feature configuration:\n\t $features"
parse_features_config "$features"
