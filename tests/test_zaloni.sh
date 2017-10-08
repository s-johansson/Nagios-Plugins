#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-12-08 11:44:27 +0000 (Thu, 08 Dec 2016)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$srcdir/.."

. "$srcdir/utils.sh"

is_travis && exit 0

section "Z a l o n i"

export ZALONI_BEDROCK_PORT="${ZALONI_BEDROCK_PORT:-8080}"

if [ -n "${ZALONI_BEDROCK_HOST:-}" ]; then
    if which nc &>/dev/null && ! echo | nc -w 1 "$ZALONI_BEDROCK_HOST" "$ZALONI_BEDROCK_PORT"; then
        echo "WARNING: Zaloni Bedrock host $ZALONI_BEDROCK_HOST:$ZALONI_BEDROCK_PORT not up, skipping Zaloni checks"
    else
        run_fail 3 ./check_zaloni_bedrock_ingestion.py -l
        hr
        run_fail "0 2" ./check_zaloni_bedrock_ingestion.py -v -r 600 -a 1440
        hr

        set +o pipefail
        ./check_zaloni_bedrock_workflow.py -l |
        tail -n +6 |
        sed 's/.*[[:space:]]\{4\}\([[:digit:]]\+\)[[:space:]]\{4\}.*/\1/' |
        while read workflow_id; do
            # TODO: fix - won't increment due to subshell
            run_fail "0 2" ./check_zaloni_bedrock_workflow.py -I "$workflow_id" -v --min-runtime 0
            hr
        done

        ./check_zaloni_bedrock_workflow.py -l |
        tail -n +6 |
        sed 's/[[:space:]]\{4\}[[:digit:]]\+[[:space:]]\{4\}.*//' |
        while read workflow_name; do
            # TODO: fix - won't increment due to subshell
            run_fail "0 2" ./check_zaloni_bedrock_workflow.py -N "$workflow_name" -v --min-runtime 0
            hr
        done
        run_fail "0 2" ./check_zaloni_bedrock_workflow.py --all -v --min-runtime 0
        hr
    fi
else
    echo "WARNING: \$ZALONI_BEDROCK_HOST not set, skipping Zaloni checks"
fi

echo "Completed $run_count Zaloni tests"
echo
echo "All Zaloni tests passed successfully"
echo
echo
