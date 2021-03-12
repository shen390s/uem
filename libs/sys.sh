add_to_env() {
    local _var _value _v

    _var="$1"
    _value="$2"

    _v=`printf "%s=\"%s\" && export %s" "$_var" "$_value" "$_var"`
    eval "$_v"
}

def_hook() {
    local _hook _v

    _hook="$1"
    _v=`printf "%s='' && export %s" "$_hook" "$_hook"`
    eval "$_v"
}

add_hook() {
    local _hook _fn _v

    _hook="$1"
    _fn="$2"

    _v=`printf "%s=\"$%s %s\" && export %s" "$_hook" "$_hook" "$_fn" "$_hook"`
    eval "$_v"
}

run_hook() {
    local _hook _v _fn _fns

    _hook="$1"
    _v=`printf "echo $%s" "$_hook"`
    _fns=`eval "$_v"`

    shift
    for _fn in $_fns; do
	eval "$_fn $@"
    done
}
