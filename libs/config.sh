
def_hook process_feature_hook

feature_name() {
    echo "$1" |sed -n -e 's/^[+-]//p'
}

process_feature_config() {
    local _feature _fn _options _fn_name 

    _feature="$1"

    _fn=`echo "$_feature" |sed -n -e 's/^\([+-][a-zA-Z0-9]\{1,\}\).*/\1/p'`
    _options=`echo "$_feature" |sed -n -e 's/^.*(\([^()]*\)).*$/\1/p'`
    _fn_name=`feature_name "$_fn"`

    case "$_fn" in
	+*)
	    run_hook process_feature_hook \
		     feature_on "$_fn_name" \
		     "$_options"
	    ;;
	-*)
	    run_hook process_feature_hook \
		     feature_off "$_fn_name"
	    ;;
    esac
}

parse_features_config() {
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
	    process_feature_config "$_data"
	fi
	
	if [ "X$_remain" = "X$_features" ]; then
	    _features=""
	else
	    _features="$_remain"
	fi
    done
}
