#!/usr/bin/env fish

complete -f -c git -n __fish_git_needs_command -a bitbucket -d 'Bitbucket helper' --wraps git-bitbucket
