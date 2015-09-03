#!/bin/sh

. ~/shell_enhancements/helpers/redirects.sh

# Extract username for given GitHub remote
github_username_for_remote () {
	git_in_repo || return 1

	local remote=$*
	if [ -z "$remote" ] ; then
		echo_error "Specify a remote"
		return 1
	fi

	# Borrowed from https://github.com/git/git/blob/master/git-parse-remote.sh#L9-L14
	# (`get_default_remote`)
	local url
	url=$(git config --get "remote.$remote.url")
	if [ -z "$url" ] ; then
		echo_error "Invalid remote"
		return 1
	fi

	# `$url` looks like `"git@github.com:foo/bar.git"` This extracts the username
	# (i.e. `"foo"`).
	#
	# TODO this is a lousy way of doing things, but grep doesn’t have capture
	# groups and sed always returns the full match.
	local username
	username=$(echo "$url" | sed "s/.*://" | sed "s/\/.*//")

	if [ -z "$username" ] ; then
		echo_error "Unable to determine username"
		return 1
	else
		echo "$username"
	fi
}
