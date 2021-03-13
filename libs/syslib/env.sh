### function for environment
add_to_env() {
    local _var _value _v _hook

    _var="$1"
    _value="$2"

    _v=`printf '%s="%s" && export %s' "$_var" "$_value" "$_var"`
    eval "$_v"

    case "$_var" in
	*hook)
	    true
	    # skip run hook for add_hook
	    ;;
	*)
	    _hook=`printf '%s_update_hook' "$_var"`
	    run_hook "$_hook" "$_value"
	    ;;
    esac
}

env_val() {
    local _var _v

    _var="$1"
    _v=`printf 'echo $%s' "$_var"`
    eval "$_v"
}

append_env() {
    local _var _v1 _v2 _v

    _var="$1"
    _v1="$2"

    _v2=`env_val "$_var"`
    if [ -z "$_v2" ]; then
	_v="$_v1"
    else
	_v="$_v2:$_v1"
    fi

    add_to_env "$_var" "$_v"
}

prefix_env() {
    local _var _v1 _v2 _v

    _var="$1"
    _v1="$2"

    _v2=`env_val "$_var"`
    if [ -z "$_v2" ]; then
	_v="$_v1"
    else
	_v="$_v1:$_v2"
    fi

    add_to_env "$_var" "$_v"
}
