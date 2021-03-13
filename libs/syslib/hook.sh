
### function for hooks
hook_defined() {
    local _hook _v _val

    _hook="$1"
    _v=`printf '%s_defined' "$_hook"`
    _val=`env_val "$_v"`

    test "X$_val" = "Xyes"
}

def_hook() {
    local _hook _v

    _hook="$1"

    # actually we need to do nothing
    DEBUG "def_hook %s" "$_hook"
    if hook_defined "$_hook"; then
	true
    else
	_v=`printf '%s_defined' "$_hook"`
	add_to_env "$_v" "yes"
	add_to_env "$_hook" ""
    fi
}

add_hook() {
    local _hook _fn 

    _hook="$1"
    _fn="$2"

    if hook_defined "$_hook"; then
	true
    else
	def_hook "$_hook"
    fi
    
    append_env "$_hook" "$_fn"
}

run_hook() {
    local _hook _fn _fns

    _hook="$1"
    _fns=`env_val "$_hook"`
    _fns=`echo $_fns |sed -e 's/:/ /g'`

    shift
    for _fn in $_fns; do
	eval "$_fn $@"
    done
}
