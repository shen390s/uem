#!/bin/sh
# -*- mode:shell-script
_appdir=`dirname $0`
TOP=`cd $_appdir/.. && pwd`
export TOP

if [ -f $TOP/libs/sys.sh ]; then
    . $TOP/libs/sys.sh
fi

# set -x
add_to_env AUTOLIB_PATH "$TOP/libs"

on_feature() {
    INFO "action: %s" "$1"
    INFO "feature: %s" "$2"
    shift 2
    while [ $# -gt 0 ]; do
	INFO "option: %s" "$1"
	shift
    done
}

dummy_action() {
    local _msg

    string_concat_to _msg "$@"
    INFO "dummy action: %s" "$_msg" 
}


features="+pkg(+nix +pkgsrc -brew -macport) +emacs -anaconda +rust +rtc"

# set -x
add_hook process_feature_hook dummy_action
add_hook process_feature_hook on_feature

parse_features_config "$features"
