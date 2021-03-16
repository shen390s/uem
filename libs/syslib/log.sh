# functions for log
_LOG_ERR=0
_LOG_WARN=1
_LOG_INFO=2
_LOG_DEBUG=5
_LOG_TRACE=10

_log_lvl=_LOG_INFO

# Setting of colors for log

test -z "$COLORS" && \
    COLORS="COLOR_ERR=196 COLOR_WARN=220 COLOR_DEBUG=2 COLOR_INFO=99"

# Show color using follow code in sh
# for c in `seq 1 254`; do tput setaf $c; echo Hello world, color $c; done

set_color() {
    local _color _val _z _c

    _color="$1"

    for _z in $COLORS; do
	_c=`echo $_z |awk -F= '{print $1}'`
	_val=`echo $_z | awk -F= '{print $2}'`
	if [ "X$_c" = "X$_color" ]; then
	    case `uname -s` in
		*BSD)
		    tput AF $_val
		    ;;
		*)
		    tput setaf $_val
		    ;;
	    esac
	    return
	fi
    done
    # no matched color set, do nothing
}

reset_color() {
    case `uname -s` in
	*BSD)
	    tput me
	    ;;
	*)
	    tput sgr0
	    ;;
    esac
}

name_to_log_lvl() {
    local _name _lvl

    _name="$1"
    case $_name in
	LOG_ERR)
	    _lvl=0
	    ;;
	LOG_WARN)
	    _lvl=1
	    ;;
	LOG_INFO)
	    _lvl=2
	    ;;
	LOG_DEBUG|LOG_DEBUG1)
	    _lvl=5
	    ;;
	LOG_DEBUG2)
	    _lvl=6
	    ;;
	LOG_DEBUG3)
	    _lvl=7
	    ;;
	LOG_TRACE)
	    _lvl=10
	    ;;
	*)
	    log_msg_with_color COLOR_ERR "ERROR" \
			       "Unknown log level. LOG_INFO will be used" >&2 
	    _lvl=2
	    ;;
    esac

    echo $_lvl
}

color_of_log_lvl() {
    local _lvl _color

    _lvl="$1"

    if [ $_lvl -eq $_LOG_ERR ]; then
	_color=COLOR_ERR
    elif [ $_lvl -eq $_LOG_WARN ]; then
	_color=COLOR_WARN
    elif [ $_lvl -eq $_LOG_INFO ]; then
	_color=COLOR_INFO
    else
	_color=COLOR_DEBUG
    fi

    echo "$_color"
}

log_lvl_name() {
    local _lvl _lvl_name

    _lvl="$1"
    case $_lvl in
	0)
	    _lvl_name="ERROR"
	    ;;
	1)
	    _lvl_name="WARN"
	    ;;
	2)
	    _lvl_name="INFO"
	    ;;
	5|6|7)
	    _lvl_name="DEBUG`expr $_lvl - 4`"
	    ;;
	10)
	    _lvl_name="TRACE"
	    ;;
	*)
	    _lvl_name="UNKNOWN"
	    ;;
    esac

    echo $_lvl_name
}

log_msg_with_color() {
    local _color _lvl_tag _fmt _msg _time _pid

    _color="$1"
    _lvl_tag="$2"
    _fmt="$3"

    shift 3
    _time=`date "+%Y-%m-%d %H:%M:%S"`
    _fmt=`printf '%-8s%s' "$_lvl_tag" "$_fmt"`
    _msg=`printf "$_fmt" "$@"`

    # set +x

    _pid="$$"
    set_color $_color
    printf "%s %6d %s\n" "$_time" "$_pid" "$_msg" 
    reset_color
}

log_msg() {
    local _lvl _color _fmt _time _msg _lvl_tag

    _lvl=`name_to_log_lvl "$1"`

    if [ $_lvl -gt $_log_lvl ]; then
	return
    fi
    
    _fmt="$2"
    shift 2
    # set -x
    _color=`color_of_log_lvl $_lvl`
    _lvl_tag=`log_lvl_name $_lvl`

    log_msg_with_color "$_color" "$_lvl_tag" "$_fmt" "$@"
}

log_init() {
    local _lvl_name

    if [ -z "$DEBUG" ]; then
	_log_lvl=$_LOG_INFO
	return
    fi

    if [ "X$DEBUG" = "XTRACE" ]; then
	_log_lvl=$_LOG_TRACE

	set -x
	return
    fi
    
    _lvl_name=`printf 'LOG_%s' $DEBUG`
    _log_lvl=`name_to_log_lvl $_lvl_name`
}

ERROR() {
    log_msg LOG_ERR "$@" >&2
}

INFO() {
    log_msg LOG_INFO "$@" >&2
}

WARN() {
    log_msg LOG_WARN "$@" >&2
}

DEBUG() {
    log_msg LOG_DEBUG "$@" >&2
}

DEBUG2() {
    log_msg LOG_DEBUG2 "$@" >&2
}

DEBUG3() {
    log_msg LOG_DEBUG3 "$@" >&2
}

log_init
