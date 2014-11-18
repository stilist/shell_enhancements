#!/bin/sh

. ~/shell_enhancements/helpers/git.sh

# Automatically pushes to the appropriate git remote.
#
# Assumes branches are named with git-flow semantics, and that development
# work is submitted through pull requests: if there’s a remote named
# `"upstream", and `$branch` starts with `develop` or `hotfix/`, `$remote`
# will be `"upstream"`. If the remote doesn’t exist, or the branch has any
# other name, `$remote` is `"origin"`.
autopush () {
	git_can_push || return 1

	local branch=$(git_current_branch)
	local remote=$(git_remote_for_git_flow)

	git_remote_exists "$remote"
	if [ "$?" -eq "0" ] ; then :
		echo "Pushing $branch to $remote"
		git push "$remote" "$branch"
	else
		echo_error "Add a git remote named 'origin'"
		return 1
	fi
}

# get line count relative to upstream
branchstat () {
	git_in_initialized_repo || return 1

	local branch=$(git_current_branch)
	local upstream=

	if [ -z "$@" ] ; then :
		upstream="master"
	else
		upstream=$1
	fi

	if [ -n "$branch" ] ; then :
		# http://www.cyberciti.biz/faq/linux-unix-appleosx-bsd-bash-passing-variables-to-awk/
		#
		# TODO break into multiple lines
		git log --numstat --pretty="%H" "$upstream..$branch" | awk -v branch="$branch" -v upstream="$upstream" 'NF==3 {plus+=$1; minus+=$2} END {printf("%s...%s: +%d, -%d, net %d\n", upstream, branch, plus, minus, (plus - minus))}'
	else
		echo ""
	fi
}

# `git push production master`
# `git push production foo:master`
deploy () {
	git_can_push || return 1

	local branch= remote=

	# `deploy to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then :
		branch=$(git_current_branch)
		remote=$2
	# `deploy foo to h_prod`
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then :
		git push "$remote" "$branch:master"
	fi
}

# `git pull`
pull () {
	git_can_push || return 1

	local branch= remote=

	# `pull from h_prod` (uses current branch)
	if [ "$1" = "from" ] ; then :
		branch=$(git_current_branch)
		remote=$2
	# `pull master from origin`
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then :
		git pull "$remote" "$branch"
	fi
}

# `git push`
push () {
	git_can_push || return 1

	local branch= remote=

	# `push to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then :
		branch=$(git_current_branch)
		remote=$2
	# `push master to origin`
	# `push production:master to origin` (for cross-branch push)
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then :
		git push "$remote" "$branch"
	fi
}

# create branch if it doesn’t exist, and automatically switch to it
# (unlike `git branch some_new_branch`)
#
# `git checkout` / `git checkout -b`
switch () {
	git_in_initialized_repo || return 1

	local branch="$1"
	# support `switch to foo` in addition to `switch foo`
	if [ "$branch" = "to" ] ; then :
		branch="$2"
	fi

	if [ -z "$branch" ] ; then :
		echo_error "Specify a branch name"
		return 1
	fi

	# http://stackoverflow.com/q/5167957/672403
	git show-ref --verify --quiet "refs/heads/$1"
	if [ "$?" -eq "0" ] ; then :
		git checkout "$branch"
	else
		git checkout -b "$branch"
	fi
}
