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
	fi
}

# get line count relative to upstream
branchstat () {
	if [ -z "$@" ] ; then :
		local upstream="master"
	else
		local upstream=$1
	fi

	local branch=$(git_current_branch)

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

	# `deploy to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then :
		local branch=$(git_current_branch)
		local remote=$2
	else
		# `deploy foo to h_prod`
		if [ "$2" = "to" ] ; then :
			local branch=$1
			local remote=$3
		fi
	fi

	if [ -n "$remote" ] ; then :
		git push "$remote" "$branch:master"
	fi
}

# `git pull`
pull () {
	git_can_push || return 1

	# `pull from h_prod` (uses current branch)
	if [ "$1" = "from" ] ; then :
		local branch=$(git_current_branch)
		local remote=$2
	# `pull master from origin`
	else
		local branch=$1
		local remote=$3
	fi

	if [ -n "$remote" ] ; then :
		git pull "$remote" "$branch"
	fi
}

# `git push`
push () {
	git_can_push || return 1

	# `push to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then :
		local branch=$(git_current_branch)
		local remote=$2
	# `push master to origin`
	# `push production:master to origin` (for cross-branch push)
	else
		local branch=$1
		local remote=$3
	fi

	if [ -n "$remote" ] ; then :
		git push "$remote" "$branch"
	fi
}

# create branch if it doesn’t exist, and automatically switch to it
# (unlike `git branch some_new_branch`)
#
# `git checkout` / `git checkout -b`
switch_b () {
	git_in_initialized_repo || return 1

	# http://stackoverflow.com/q/5167957/672403
	git show-ref --verify --quiet "refs/heads/$1"
	if [ "$?" -eq "0" ] ; then :
		git checkout "$1"
	else
		git checkout -b "$1"
	fi
}
