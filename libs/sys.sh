### function for environment
add_to_env() {
    local _var _value _v

    _var="$1"
    _value="$2"

    _v=`printf '%s="%s" && export %s' "$_var" "$_value" "$_var"`
    eval "$_v"
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
	_v="$_v2 $_v1"
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
	_v="$_v1 $_v2"
    fi

    add_to_env "$_var" "$_v"
}
### function for hooks
def_hook() {
    local _hook 

    _hook="$1"

    add_to_env "$_hook" ""
}

add_hook() {
    local _hook _fn 

    _hook="$1"
    _fn="$2"

    append_env "$_hook" "$_fn"
}

run_hook() {
    local _hook _fn _fns

    _hook="$1"
    _fns=`env_val "$_hook"`

    shift
    for _fn in $_fns; do
	eval "$_fn $@"
    done
}
