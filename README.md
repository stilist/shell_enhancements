A little like `dotfiles`.

## Usage

1. `cd ~` (currently has to be at root: see [#1](https://github.com/stilist/shell_enhancements/issues/1))
1. `git clone git@github.com:stilist/shell_enhancements.git`

Add this to your `.bash_profile` (or `.profile`, if you’re not using Bash):

	for file in ~/shell_enhancements/*.sh ; do
		[ -r "$file" ] && [ -f "$file" ] && source "$file";
	done;
	unset file;
