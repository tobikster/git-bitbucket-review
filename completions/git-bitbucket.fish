#!/usr/bin/env fish

function __fish_remotes_configured_for_bitbucket_review -d "Get a list of git remotesd, which have been configured to be used with the git-bitbucket-review command"
    set -l remotes (__fish_git_remotes)
    for r in $remotes
        __fish_git config --get "bitbucketreview."$r".bitbucket-url" &>/dev/null
        set -l remote_configured $status
        if test $remote_configured -eq 0
            echo $r
        end
    end
end

function __fish_get_bitbucket_pullrequests -d "Get open pull requests from the BitBucket server"
    function __format_bitbucket_url
        set -l base_url "$argv[1]"
        set -l project "$argv[2]"
        set -l repo "$argv[3]"

        echo "$base_url/rest/api/1.0/projects/$project/repos/$repo/pull-requests"
    end

    set -l cmd (commandline -opc)
    set -l remotes (__fish_remotes_configured_for_bitbucket_review)
    set -l remote $cmd[3]

    set -l oauth_token_variable (__fish_git config --get "bitbucketreview.$remote.oauth-token-variable")

    set -l bitbucket_base_url (__fish_git config --get "bitbucketreview.$remote.bitbucket-url")
    set -l bitbucket_project (__fish_git config --get "bitbucketreview.$remote.project")
    set -l bitbucket_repo (__fish_git config --get "bitbucketreview.$remote.repo")

    set -l base_pull_requests_uri (__format_bitbucket_url $bitbucket_base_url $bitbucket_project $bitbucket_repo)
    set -l pull_requests_uri $base_pull_requests_uri"?state=OPEN&order=OLDEST"

    functions -e __format_bitbucket_url

    curl -s -LC - --oauth2-bearer "$$oauth_token_variable" "$pull_requests_uri" | jq -r '.values[] | {"id": .id, "title": .title, "target": .toRef.displayId, "author": .author.user.name} | "\(.id)\t[\(.author)] \(.title) -> \(.target)"' # 2>/dev/null
end

function __fish_last_argument_matches -d "Check if last argument on the command line mathes the regex"
    set -l last_argument (commandline -poc)[-1]
    string match -ar $argv[1] $last_argument >/dev/null
end

set -l subcommands review

complete -f -c git-bitbucket -n "not __fish_seen_subcommand_from $subcommands" -a review -d "Review a PR from Bitbucket"
complete -f -c git-bitbucket -n "__fish_seen_subcommand_from review; and not __fish_seen_subcommand_from (__fish_git_remotes)" -a "(__fish_remotes_configured_for_bitbucket_review)" -d Remote
complete -f -c git-bitbucket -n "__fish_seen_subcommand_from review; and __fish_seen_subcommand_from (__fish_git_remotes); and not __fish_last_argument_matches \"^\d+\\\$\"" -a "(__fish_get_bitbucket_pullrequests)"
complete -f -c git-bitbucket -n "__fish_seen_subcommand_from review; and __fish_seen_subcommand_from (__fish_git_remotes); and __fish_last_argument_matches \"^\d+\\\$\""
