feature_name() {
    echo "$1" |sed -n -e 's/^[+-]//p'
}

option_name() {
    feature_name "$1"
}

on_option() {
    local _fn _opt

    _fn="$1"
    _opt="$2"

    _v=`printf "%s_%s=on && export %s_%s" "$_fn" "$_opt" "$_fn" "$_opt"`
    eval "$_v"
}

off_option() {
    local _fn _opt _v
    _fn="$1"
    _opt="$2"

    _v=`printf "%s_%s=off && export %s_%s" "$_fn" "$_opt" "$_fn" "$_opt"`
    eval "$_v"
}

activate_feature() {
    local _fn _i _v

    _fn="$1"

    _i=1

    _v=`printf "%s_enabled=yes && export %s_enabled" "$_fn" "$_fn"`
    eval "$_v"
    
    while [ $_i -lt $# ]; do
	shift
	case "$1" in
	    +*)
		on_option "$_fn" `option_name "$1"`
		;;
	    -*)
		off_option "$_fn" `option_name "$1"`
		;;
	esac
    done
}

deactivate_feature() {
    local _fn

    _fn="$1"

    echo "deactivate $_fn"
}



process_feature() {
    local _feature _fn _options

    _feature="$1"

    _fn=`echo "$_feature" |sed -n -e 's/^\([+-][a-zA-Z0-9]\{1,\}\).*/\1/p'`
    _options=`echo "$_feature" |sed -n -e 's/^.*(\([^()]*\)).*$/\1/p'`

    case "$_fn" in
	+*)
	    activate_feature `feature_name "$_fn"` \
			     $_options
	    ;;
	-*)
	    deactivate_feature `feature_name "$_fn"`
	    ;;
    esac
}

parse_features() {
    local _features _data _remain

    _features="$1"
    while :; do
	if [ -z "$_features" ]; then
	    break
	fi

	_data=`echo $_features | sed -n -e 's/^[ \t]*\([+-][a-zA-Z0-9]\{1,\}([^()]*)\).*$/\1/p'`
	if [ -z "$_data" ]; then
	    _data=`echo $_features | sed -n -e 's/^[ \t]*\([+-][a-zA-Z0-9]\{1,\}\).*$/\1/p'`
	    _remain=`echo $_features | sed -n -e 's/^[ \t]*\([+-][a-zA-Z0-9]\{1,\}\)//p'`
	else
	    _remain=`echo $_features | sed -n -e 's/^[ \t]*[+-][a-zA-Z0-9]\{1,\}([^()]*)//p'`
	fi

	if [ -z "$_data" ]; then
	    :
	else
	    process_feature "$_data"
	fi
	
	if [ "X$_remain" = "X$_features" ]; then
	    _features=""
	else
	    _features="$_remain"
	fi
    done
}
