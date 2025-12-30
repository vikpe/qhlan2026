#!/bin/bash

# usage
# 1. put this script into the demo dir
# 2. make sure its executable "chmod +x update_ffa_frags.sh"
# 3. update aws configuration below
# 4. run it "./update_ffa_frags.sh"

# aws configuration
export AWS_ACCESS_KEY_ID="GET_FROM_XANTOM"
export AWS_SECRET_ACCESS_KEY="GET_FROM_XANTOM"
export AWS_DEFAULT_REGION="eu-north-1"

# prerequisites
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Installing..."
    sudo apt install -y awscli
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing..."
    sudo apt install -y jq
fi

if ! command -v inotifywait &> /dev/null; then
    echo "inotify-tools not found. Installing..."
    sudo apt install -y inotify-tools
fi

# run whenever a ffa_*.txt is created in the current dir
inotifywait -m -e close_write --format "%f" "." | while read FILE
do
    if [[ "$FILE" == ffa_*.txt ]]; then
        # summarize frags per player
        jq -s '[.[] | .players[] | {name: .name, frags: .stats.frags}] |
            group_by(.name) |
            map({name: .[0].name, frags: map(.frags) | add})
            | sort_by(.frags) | reverse
        ' ffa_*.txt > ffa_frags.json

        # upload to aws s3
        # public url: https://qhlan2026.s3.eu-north-1.amazonaws.com/ffa_frags.json
        aws s3 cp ffa_frags.json s3://qhlan2026/ffa_frags.json --content-type application/json --cache-control "no-store, no-cache, must-revalidate, max-age=0" --expires 0
    fi
done
