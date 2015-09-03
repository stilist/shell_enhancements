#!/bin/sh

if hash rbenv 2> /dev/null ; then
	eval "$(rbenv init -)"
fi

be () {
	bundle exec "$@"
}
ber () {
	bundle exec rake "$@"
}
