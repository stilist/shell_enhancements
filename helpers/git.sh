#!/bin/sh

. ~/shell_enhancements/helpers/redirects.sh

git_in_repo () {
	redirect_to_null git status -unormal
	if [ "$?" -eq "0" ] ; then :
		return 0
	else
		echo_error "Not in a git repository"
		return 1
	fi
}

git_in_initialized_repo () {
	redirect_to_null git_in_repo || return 1

	local git_status=$(git status -unormal 2>&1)
	case "$git_status" in
		*"Initial commit"* ) return 1 ;;
		*                  ) return 0 ;;
	esac
}

git_can_push () {
	redirect_to_null git_in_repo || return 1
	git_in_initialized_repo || return 1
}

git_current_branch () {
	redirect_to_null git_in_repo || return 1

	git_in_initialized_repo
	if [ "$?" -ne "0" ] ; then :
		echo "[new repo]"
	else
		# http://stackoverflow.com/a/11958481/672403
		git rev-parse --symbolic-full-name --abbrev-ref HEAD
	fi
}

git_remote_exists () {
	git_in_initialized_repo || return 1

	if [ -z "$@" ] ; then
		echo_error "Specify a remote"
		return 1
	else
		git remote | redirect_to_null grep "$@"
	fi
}

git_remote_for_git_flow () {
	local branch=$(git_current_branch)
	# default to `"origin"`
	local remote=

	git_in_initialized_repo || return 1

	git_remote_exists upstream
	if [ "$?" -eq "0" ] ; then :
		case "$branch" in
			"develop" ) remote="upstream" ;;
			hotfix/*  ) remote="upstream" ;;
			*         ) remote="origin" ;;
		esac
	else
		remote="origin"
	fi

	echo $remote
}
