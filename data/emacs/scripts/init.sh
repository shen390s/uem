#! /bin/sh
#
if [ "x$DEBUG" = "xyes" ]; then
    set -x
fi
datadir=""
force="no"
destdir=$HOME/.emacs.d

dir_empty_p() {
    local _dir _nf

    _dir="$1"

    _nf=$(ls $_dir |wc -l)
    if [ "x$_nf" = "x0" ]; then
        true
    else
        false
    fi
}

emacs_init() {
    local _dir _force _datadir _it

    _dir="$1"
    _force="$2"
    _datadir="$3"

    if [ -d "$_dir" ]; then
        if dir_empty_p "$_dir"; then
            :
        elif [ "x$_force" = "xyes" ]; then
            rm -Rf $_dir && mkdir -p "$_dir"
        else
            echo "Directory $_dir is not empty, please choose another directory or use -f option"
            exit 1
        fi
    else
        mkdir -p "$_dir"
    fi

    for _it in uem.el init.el early-init.el; do
        cp $_datadir/emacs/startup/$_it $_dir
    done

    echo uem emacs init ok at: $_dir
}

while [ $# -gt 0 ]; do
    case "$1" in
        --data-dir=*)
            datadir=$(echo $1 |awk -F= '{print $2}')
            shift
            ;;
        --force)
            force="yes"
            shift
            ;;
        *)
            echo Unknown options
            exit 2
            ;;
    esac
done

if [ -z "$datadir" ]; then
    echo no data directory specified
    exit 1
fi

emacs_init $destdir $force $datadir

exit 0
