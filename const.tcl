#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

namespace eval const {
    set tool_name "eMap Create"
    set start_title "Set Map Size"
}

