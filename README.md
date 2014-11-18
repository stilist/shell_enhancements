A little like `dotfiles`.

## Usage

1. `cd ~`
1. `git clone git@github.com:stilist/shell_enhancements.git`
1. Add this to your `.bash_profile` (or `.profile`, if you’re not using Bash):

	for file in ~/shell_enhancements/*.sh ; do
		[ -r "$file" ] && [ -f "$file" ] && source "$file";
	done;
	unset file;
