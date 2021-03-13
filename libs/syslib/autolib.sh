_autolib_tag="###;;;AUTOLIB"

# some misc functions
string_concat_to() {
    local _var _z1

    _var="$1" && shift
    _z1=`printf '%s="%s"' $_var "$*"`
    eval "$_z1"
}

# autolib functions
def_hook AUTOLIB_PATH_update_hook

autolib_id() {
    local _m _line _name _uuid

    _m="$1"
    _line=`head -n1 $_m`

    if echo $_line |grep "$_autolib_tag" 2>&1 >/dev/null; then
	:
    else
	DEBUG "no tag found for file: %s. Skip it" $_m
	return
    fi

    _name=`echo $_line|awk -F: '{print $2}'`
    if [ -z "$_name" ]; then
	DEBUG "incorrect tag, name missed for file: %s. Skip it" $_m
	return
    fi
    
    _uuid=`echo $_line|awk -F: '{print $3}' | tr "[:upper:]" "[:lower:]"`
    if [ -z "$_uuid" ]; then
	WARN "incorrect tag, no uuid for file: %s. Skip it" $_m
	return
    fi
    
    printf "%s_%s\n" $_name $_uuid | sed -e 's/-/_/g' 
}

find_autolib() {
    local _check_fn _m _dirs _d _val

    _check_fn="$1"
    _m="$2"
    _dirs="$3"

    while : ; do
	if [ -z "$_dirs" ]; then
	    break
	fi

	_d=`echo $_dirs | awk -F: '{print $1}'`
	_val=`eval "$_check_fn $_d $_m"`

	if [ ! -z "$_val" ]; then
	    echo $_val
	    return
	fi

	if [ "X$_d" = "X$_dirs" ]; then
	    break
	else
	    _dirs=`echo $_dirs | sed -e 's/^[^:]*://'`
	fi
    done

    echo
}

do_check() {
    local _check_fn _path

    _check_fn="$1"
    _path="$2"

    if eval "$_check_fn $_path" ; then
	echo $_path
    elif eval "$_check_fn $_path.sh" ; then
	echo $_path.sh
    else
	echo
    fi
}

have_autolib() {
    local _id

    if test -f "$1" 2>&1 >/dev/null; then
	_id=`autolib_id "$1"`
	test ! -z "$_id"
    else
	false
    fi
}

executable_file() {
    test -x "$1" 2>&1 >/dev/null
}

check_req_autolib() {
    do_check have_autolib "$1/$2"
}

autolib_loaded() {
    local _m _mid _load_tag  _val

    _m="$1"
    _mid=`autolib_id $_m`

    test -z "$_mid" && \
	false && \
	return

    _load_tag=`printf 'autolib_%s_loaded' $_mid`
    _val=`env_val "$_load_tag"`

    test "X$_val" = "Xyes"
}

set_autolib_loaded() {
    local _m _mid _load_tag _z

    _m="$1"
    _mid=`autolib_id $_m`

    test -z "$_mid" && \
	false && \
	return

    _load_tag=`printf 'autolib_%s_loaded' $_mid`
    add_to_env "$_load_tag" "yes"
}

do_autolib_load() {
    local _m _val

    _m="$1"

    autolib_loaded "$_m" && \
	true && \
	return

    . $_m
    _val=$?

    set_autolib_loaded "$_m"
    
    return $_val
}

require() {
    local _m _dirs _val 

    _m="$1"

    test -z "$_m" && \
	echo "no autolib in require clause" && \
	return 1
    
    _dirs="$AUTOLIB_PATH"

    case $_m in
	/*)
	    # absolute path, just use it
	    _val="$_m"
	    ;;
	*)
	    _val=`find_autolib check_req_autolib "$_m" "$_dirs"`
	    ;;
    esac

    if [ -z "$_val" ]; then
	ERROR "Require autolib: %s can not be found in: %s" $_m $_dirs
	return 1
    else
	do_autolib_load "$_val"
    fi
}

mk_autoload_script() {
    local _f _fn

    _f=`basename $1`
    _fn="$2"
    
    cat <<EOF
$_fn () {
     require $_f
     $_fn "\$@"
}
EOF
}

set_fn_autoload() {
    local _fn _f _z

    _fn="$1"
    _f="$2"

    _z=`printf '%s_autoload' "$_fn"`
    add_to_env "$_z" "$_f"
}

get_fn_autoload() {
    local _fn _z 

    _fn="$1"
    _z=`printf '%s_autoload' "$_fn"`

    env_val "$_z"
}

mk_autoload() {
    local _f _fn _cmd _f1 _rc _fmt

    _f="$1"
    _fn="$2"

    _f1=`get_fn_autoload "$_fn"`

    if [ ! -z "$_f1" ]; then
	if [ "X$_f1" = "X$_f" ]; then
	    DEBUG "function %s has already been loaded from %s" \
		  $_fn $_f
	    return 0
	else
	    string_concat_to _fmt \
			     "conflict autoload function %s\n" \
			     "      both in:\n" \
			     "              %s\n" \
			     "              %s\n"
	    ERROR "$_fmt" $_fn $_f1 $_f
	    return 1
	fi
    fi
    
    _cmd=`mk_autoload_script "$_f" "$_fn"`

    eval "$_cmd"
    _rc=$?

    set_fn_autoload "$_fn" "$_f"
    return $_rc
}

get_autoload_fns() {
    local _f

    _f="$1"

    cat "$_f" 2>/dev/null | \
	sed -n -e '/^###;;;autoload/{n;P;}' | \
	sed -e 's/^\([a-zA-Z0-9_]*\).*$/\1/g' |\
	xargs echo
}

mk_file_autoload() {
    local _f _fns _fn 

    _f="$1"

    # if the autolib has been loaded, no need
    # to generate autoload functions
    autolib_loaded "$_f" && \
	return
    
    _fns=`get_autoload_fns $_f`
    for _fn in $_fns; do
	mk_autoload "$_f" "$_fn"
    done
}

mk_dir_autoload() {
    local _d _files _f _id

    _d="$1"

    test -z "$_d" && \
	return
    
    _files=`ls $_d/* 2>/dev/null`

    for _f in $_files; do
	case $_f in
	    \#* | *\# | *~ | ~*)
		continue
		;;
	    *)
		;;
	esac

	# ignore sub-directory
	if [ ! -f $_f ]; then
	    continue
	fi
	
	_id=`autolib_id $_f`
	if [ -z "$_id" ]; then
	    continue
	fi

	mk_file_autoload "$_f"
    done
}

autoload_dirs() {
    local _d _dirs

    _dirs="$1"
    for _d in `echo $_dirs |sed -e 's/:/ /g'`; do
	mk_dir_autoload "$_d"
    done
}

add_autolib_header() {
    local _m _name _uuid _header

    _m="$1"

    if head -n 1 $_m |grep $_autolib_tag 2>&1 >/dev/null; then
	true
	return
    fi

    _name=`basename $_m |sed -e 's/\.sh//g'`
    _uuid=`uuidgen`

    _header=`printf "%s:%s:%s" $_autolib_tag $_name $_uuid`
    mv $_m $_m.old
    echo $_header >$_m
    cat $_m.old >>$_m
    rm -Rf $_m.old
}

# setup hook function to handle autoload
#
add_hook AUTOLIB_PATH_update_hook autoload_dirs
