#!/bin/sh

# https://twitter.com/michaelhoffman/status/639178277786136576
HOSTNAME="$(hostname)"
# changes e.g. `foobar.local` to `foobar`
HOSTNAME_SHORT="${HOSTNAME%%.*}"
# https://twitter.com/michaelhoffman/status/639178145673932800
# note: on OS X 10.11 beta, bash wouldn’t save history with the original
#   `%Y/%m/%d` formatting, perhaps because the directory structure didn’t exist
# note: `$$` appends the PID
export HISTFILE
HISTFILE="$HOME/.history/$(date -u +%Y-%m-%dT%H.%M.%S)_${HOSTNAME_SHORT}_$$"

# commands entered with leading whitespace are not saved in history
export HISTCONTROL=ignorespace

# don’t truncate history
export HISTFILESIZE=10000000

# append to history file instead of overwriting
# note: `shopt` is a Bashism, so check for its existence as a shell builtin
which type
if [ "$?" -eq "0" ] ; then
	type shopt | grep "builtin" && shopt -s histappend
fi

# save history when commands are run, rather than at the end of the session
export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# https://twitter.com/michaelhoffman/status/639226401015525376
histgrep () {
	grep -r "$@" ~/.history
	history | grep "$@"
}
