#!/bin/sh

. ~/shell_enhancements/helpers/git.sh
. ~/shell_enhancements/helpers/gitflow.sh
. ~/shell_enhancements/helpers/github.sh
. ~/shell_enhancements/helpers/redirects.sh

# Automatically pushes to the appropriate git remote.
#
# Assumes branches are named with git-flow semantics, and that development
# work is submitted through pull requests: if there’s a remote named
# `"upstream", and `$branch` starts with `develop` or `hotfix/`, `$remote`
# will be `"upstream"`. If the remote doesn’t exist, or the branch has any
# other name, `$remote` is `"origin"`.
autopush () {
	git_can_push || return 1

	local branch
	branch=$(git_current_branch)
	local remote
	remote=$(gitflow_remote "$branch")

	git_remote_exists "$remote"
	if [ "$?" -eq "0" ] ; then
		echo "Pushing $branch to $remote"
		git push "$remote" "$branch"
	else
		echo_error "Add a git remote named 'origin'"
		return 1
	fi
}

# Automatically open a GitHub pull request to the appropriate git remote and
# comparison base.
#
# Much like `autopush`, `autopr` assumes git-flow semantics in order to
# operate: it looks at the current branch name to determine which remote to
# use. The [`hub`](https://hub.github.com/) tool is used to open a pull request
# with the appropriate base.
autopr () {
	local message=$*

	if [ -z "$message" ] ; then
		echo_error "A message is required"
		return 1
	fi

	git_can_push || return 1

	# need `hub` to use `pull-request` command
	redirect_to_null hash hub
	if [ "$?" -ne "0" ] ; then
		echo_error "You don’t have hub installed: brew install --HEAD hub"
		return 1
	fi

	local remote
	git_remote_exists "upstream"
	if [ "$?" -eq "0" ] ; then
		remote="upstream"
	else
		remote="origin"
	fi
	local upstream_user
	upstream_user=$(github_username_for_remote "$remote")
	local origin_user
	origin_user=$(github_username_for_remote "origin")

	local branch
	branch=$(git_current_branch)
	local remote_branch
	remote_branch=$(gitflow_branch_base "$branch")
	if [ -n "$remote_branch" ] ; then
		echo "Opening a pull request against $upstream_user:$remote_branch"
		hub pull-request -m "$message" -b "$upstream_user:$remote_branch" -h "$origin_user:$branch"
	fi
}

# get line count relative to upstream
branchstat () {
	git_in_initialized_repo || return 1

	local branch
	branch=$(git_current_branch)
	local upstream

	if [ -z "$@" ] ; then
		upstream="master"
	else
		upstream=$1
	fi

	if [ -n "$branch" ] ; then
		# http://www.cyberciti.biz/faq/linux-unix-appleosx-bsd-bash-passing-variables-to-awk/
		#
		# TODO break into multiple lines
		git log --numstat --pretty="%H" "$upstream..$branch" | awk -v branch="$branch" -v upstream="$upstream" 'NF==3 {plus+=$1; minus+=$2} END {printf("%s...%s: +%d, -%d, net %d\n", upstream, branch, plus, minus, (plus - minus))}'
	else
		echo ""
	fi
}

# Largely the same as `push`, but automatically pushes to remote `master`.
#
# `git push production master`
# `git push production foo:master`
deploy () {
	git_can_push || return 1

	local branch
	local remote

	# `deploy to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then
		branch=$(git_current_branch)
		remote=$2
	# `deploy foo to h_prod`
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then
		git push "$remote" "$branch:master"
	fi
}

# `git pull -r origin foo`
grebase () {
	git_can_push || return 1

	local branch
	local remote

	# `grebase origin master`
	if [ -n "$2" ] ; then
		branch=$2
		remote=$1
	else
		remote="origin"
	fi

	if [ -z "$branch" ] ; then
		# `grebase master`
		if [ -n "$1" ] ; then
			branch=$1
		# `grebase`
		else
			branch=$(git_current_branch)
		fi
	fi

	git pull -r "$remote" "$branch"
}

# `git pull`
pull () {
	git_can_push || return 1

	local branch
	local remote

	# `pull from h_prod` (uses current branch)
	if [ "$1" = "from" ] ; then
		branch=$(git_current_branch)
		remote=$2
	# `pull master from origin`
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then
		git pull "$remote" "$branch"
	fi
}

# `git push`
push () {
	git_can_push || return 1

	local branch
	local remote

	# `push to h_prod` (uses current branch)
	if [ "$1" = "to" ] ; then
		branch=$(git_current_branch)
		remote=$2
	# `push master to origin`
	# `push production:master to origin` (for cross-branch push)
	else
		branch=$1
		remote=$3
	fi

	if [ -n "$remote" ] ; then
		git push "$remote" "$branch"
	fi
}

# Check out a branch, creating the branch if it doesn’t already exist.
# Determines if the branch exists by checking local branches, then known remote
# branches.
#
# `git checkout` / `git checkout -b` / `git checkout -t`
switch () {
	git_in_initialized_repo || return 1

	local branch
	branch="$1"
	# support `switch to foo` in addition to `switch foo`
	if [ "$branch" = "to" ] ; then
		branch="$2"
	fi

	if [ -z "$branch" ] ; then
		echo_error "Specify a branch name"
		return 1
	fi

	# http://stackoverflow.com/q/5167957/672403
	#
	# Is there a local branch named `$1`?
	git show-ref --verify --quiet "refs/heads/$1"
	if [ "$?" -eq "0" ] ; then
		git checkout "$branch"
	else
		# Does git know about a remote branch named `$1`?
		git show-ref --verify --quiet "refs/remotes/origin/$1"
		if [ "$?" -eq "0" ] ; then
			git checkout -t "origin/$1"
		else
			git checkout -b "$branch"
		fi
	fi
}
