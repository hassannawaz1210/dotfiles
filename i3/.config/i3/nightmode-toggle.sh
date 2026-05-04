#!/bin/sh
# Toggle redshift warm/neutral. Marker file tracks state.
marker="${XDG_RUNTIME_DIR:-/tmp}/nightmode.on"
if [ -f "$marker" ]; then
    redshift -x
    rm -f "$marker"
else
    redshift -O 3500
    touch "$marker"
fi
