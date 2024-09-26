#!/usr/bin/env sh

DOOM_INSTALL_DIR="$1"
DOOM_DATADIR="$HOME/.doom.d"

gen_doom_profile() {
    cat <<EOF
(:name "doom"
 :directory "$DOOM_INSTALL_DIR"
 :server-name "doom"
 :environ (("DOOMDIR" . "$DOOM_DATADIR")))
EOF
}

# clone doomemacs
# run doom install
# create install script
# add doom profile

true
