#!/usr/bin/env bash

# https://stackoverflow.com/a/2990533
echoerr() {
    printf "%s\n" "$*" >&2;
}

ME=$(basename ${BASH_SOURCE[0]})

if ! command -v fzf &> /dev/null
then
    echo 'fzf' could not be found. Install before retrying.
    exit 1
fi

# Get profile
if [ "$#" -ge 1 ]; then
    PROFILE=$1
else
    PROFILE=$(aws configure list-profiles | fzf)
fi

# Output AWS_PROFILE
if [[ ! -z $YK_FISH_EXISTS ]]; then
    # User is using Fish
    if [[ -z ${IS_FISH_SOURCED} ]]; then
        echo "To use AWS environment, run:"
        echo "aws configure sso (one time), then aws sso login"
        echo "set -x AWS_PROFILE $PROFILE"
        echo
        echo "Hint: To set this automatically, use"
        echo "fs $ME $@"
    else
        # User is running this command with the source prefix 'fs'

        echo export AWS_PROFILE=$PROFILE
    fi
elif [[ ! -z ${BASH} ]]; then
    # Using is using Bash
    [[ "${BASH_SOURCE[0]}" != "${0}" ]] && IS_SOURCED=true

    if [[ $IS_SOURCED = "true" ]]; then
        # Using is running this command with the source prefix '.' or 'source'
        export AWS_PROFILE="$PROFILE"
    else
        echo "To use AWS environment, run:"
        echo "aws configure sso (one time), then aws sso login"
        echo "export AWS_PROFILE=$PROFILE"
        echo
        echo "Hint: To set this automatically, use"
        echo ". $ME $@"
    fi
else
    echo "Terminal is not supported, so you will have to set this environment variable manually:"
    echo AWS_PROFILE="$PROFILE"
fi
