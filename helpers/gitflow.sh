#!/bin/sh

. ~/shell_enhancements/helpers/git.sh
. ~/shell_enhancements/helpers/redirects.sh

# These commands help with repositories managed with gitflow semantics.
#
# If the user has `git-flow` installed (`brew install git-flow`) and is in a
# repo that has been set up with `git flow init`, the commands will attempt to
# use the `git-flow` names the user has set up.
#
# For general information on gitflow:
#
# * http://danielkummer.github.io/git-flow-cheatsheet/
# * http://nvie.com/posts/a-successful-git-branching-model/

gitflow_initialized () {
	redirect_to_null git config --get-regexp gitflow
}

# Gives the default branch prefixes according to gitflow semantics.
gitflow_default_prefix () {
	local branch_type=$1
	if [ -z "$branch_type" ] ; then
		echo_error "Specify a branch type (e.g. hotfix, release)"
		return 1
	fi

	local prefix=

	case "$branch_type" in
		develop|master         ) prefix="$branch_type" ;;
		feature|hotfix|release ) prefix="$branch_type/" ;;
		*                      ) prefix="" ;;
	esac

	if [ -z "$prefix" ] ; then
		echo_error "Branch type doesn’t match gitflow semantics"
		return 1
	else
		echo "$prefix"
	fi
}

# `git-flow` stores the following general info in each initialized repo’s
# `git-config`:
#
# * `gitflow.branch.master`
# * `gitflow.branch.develop`
# * `gitflow.prefix.feature`
# * `gitflow.prefix.release`
# * `gitflow.prefix.hotfix`
# * `gitflow.prefix.support`
# * `gitflow.prefix.versiontag`
#
# `gitflow_prefix` attempts to look these up; if they’re not available (i.e.
# `git-flow` has not been set up for the repo) it falls back to
# `gitflow_default_prefix`.
gitflow_prefix () {
	local branch_type=$1
	if [ -z "$branch_type" ] ; then
		echo_error "Specify a branch type (e.g. hotfix, release)"
		return 1
	fi

	local prefix=

	local match=$(git config --get "gitflow.prefix.$branch_type")
	if [ -n "$match" ] ; then
		prefix="$match"
	# `develop` and `master` are under `gitflow.branch` instead of
	# `gitflow.prefix`
	elif [ "$branch_type" = "develop" -o "$branch_type" = "master" ] ; then
		local branch=$(git config --get "gitflow.branch.$branch_type")
		if [ -z "$branch" ] ; then
			prefix="$branch"
		fi
	fi

	# `git-flow` doesn’t have anything; try defaults
	if [ -z "$prefix" ] ; then
		# TODO this gets around `echo_error` showing the same message twice if the
		# branch doesn’t match, but calling a function twice isn’t great either.
		redirect_to_null gitflow_default_prefix "$branch_type"
		if [ "$?" -eq "0" ] ; then
			prefix=$(gitflow_default_prefix "$branch_type")
		fi
	fi

	# defaults don’t work either; give up
	if [ -z "$prefix" ] ; then
		echo_error "Branch type doesn’t match gitflow semantics"
		return 1
	else
		echo "$prefix"
	fi
}

# If a branch is set up with `git-flow`, `git-config` will have information
# about what the base branch: which branch this one was forked from and should
# merge to. This is stored under `gitflow.branch.*.base`, e.g.
# `gitflow.branch.hotfix/brains.base`.
#
# If the branch *wasn’t* set up with `git-flow` (the `gitflow.branch` key is
# missing), `gitflow_branch_base` guesses the base branch according to general
# gitflow semantics.
gitflow_branch_base () {
	local branch=$1
	if [ -z "$branch" ] ; then
		echo_error "Specify a branch name"
		return 1
	fi

	local base=

	local match=$(git config --get "gitflow.branch.$branch.base")
	# gitflow has recorded the base
	if [ -n "$match" ] ; then
		base="$match"
	# use defaults
	else
		local develop=$(gitflow_prefix "develop")
		local hotfix=$(gitflow_prefix "hotfix")

		case "$branch" in
			$hotfix* ) base="master" ;;
			*        ) base="$develop" ;;
		esac
	fi

	echo "$base"
}

# Determine base remote from available remotes using branch name.
#
# If 1) there’s a remote named `"upstream"` and 2) the branch name is
# `"develop"` or `"master"`, or is a hotfix branch, `"upstream"` will be used.
# Otherwise, `"origin"` will be.
gitflow_remote () {
	local branch=$1
	if [ -z "$branch" ] ; then
		echo_error "Specify a branch name"
		return 1
	fi

	local remote=

	git_in_initialized_repo || return 1

	git_remote_exists "upstream"
	if [ "$?" -eq "0" ] ; then
		local develop=$(gitflow_prefix "develop")

		case "$branch" in
			$develop|master ) remote="upstream" ;;
			*               ) remote="origin" ;;
		esac
	else
		remote="origin"
	fi

	echo $remote
}
