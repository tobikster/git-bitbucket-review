function __fish_remotes_configured_for_bitbucket_review -d "Get a list of git remotesd, which have been configured to be used with the git-bitbucket-review command"
	set -l remotes (__fish_git_remotes)
	for r in $remotes
		__fish_git config --get "bitbucketreview."$r".pullrequestsurl" &> /dev/null
		set -l remote_configured $status
		if test $remote_configured -eq 0
			echo $r
		end
	end
end

function __fish_get_bitbucket_pullrequests -d "Get open pull requests from the BitBucket server"
	set -l remotes (__fish_remotes_configured_for_bitbucket_review)
	set -l remote
	set -l cmd (commandline -opc)

	for r in $remotes
		if contains -- $r $cmd
			set remote $r
			break
		end
	end
	
	set -q remote[1]; or return 1

	set -l oauth_token (__fish_git config --get "bitbucketreview."$remote".oauthtoken")
	set -l base_pull_requests_uri (__fish_git config --get "bitbucketreview."$remote".pullrequestsurl") 
	set -l pull_requests_uri $base_pull_requests_uri"?state=OPEN&order=OLDEST"

	curl -s -LC - --oauth2-bearer "$oauth_token" "$pull_requests_uri" | jq -r '.values[] | [.id, .title] | @tsv' 2> /dev/null
end

set -l bitbucket_review_command "bitbucket-review"

complete -f -c git -n "__fish_git_needs_command" -a $bitbucket_review_command -d "Review a Bitbucket's pull request"
complete -f -c git -n "__fish_git_using_command $bitbucket_review_command; and not __fish_seen_subcommand_from (__fish_git_remotes)" -a "(__fish_remotes_configured_for_bitbucket_review)" -d "Remote"
complete -f -c git -n "__fish_git_using_command $bitbucket_review_command; and __fish_seen_subcommand_from (__fish_git_remotes)" -a "(__fish_get_bitbucket_pullrequests)"