#!/bin/sh

# http://stackoverflow.com/a/2990533/672403
#
# `echo` all passed arguments to to stderr and exit with error
echo_error () {
	echo "$@" 1>&2
}

# Silences stderr and stdout, so the only return is the exit status
redirect_to_null () {
	"$@" >/dev/null 2>&1
}
