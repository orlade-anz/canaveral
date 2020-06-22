#!/bin/bash

# Usage:
# export CANAVAREL_ACCESS_TOKEN=foo
# export CANAVAREL_ENTERPRISE_ACCESS_TOKEN=bar

edomain="github.enterprise.corp"

# curl https://api.github.com/orgs/anz-bank/repos -H "Authorization: token $CANAVAREL_ACCESS_TOKEN"
# curl https://$edomain/api/v3/orgs/dcx/repos -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN"
# curl -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN" https://$edomain/api/v3/organizations
# curl -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN" https://$edomain/api/v3/repositories
# curl -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN" https://$edomain/api/v3/repositories | arrai jx | arrai eval '//eval.value(//os.stdin).a count'
# curl -H 'Authorization: token 746da3b86fb72be4d132d1f0b472a902fe1a7452' 'https://$edomain/api/v3/search/code?q=!type+extension:sysl' | jq '[.items | .[].repository.full_name] | unique | sort'

tmp="tmp"

fetch_repos() {
    cmd=( curl -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN" "https://$edomain/api/v3/repositories?$1" -D $tmp/head.txt )
    >&2 echo ">> ${cmd[@]}"
    ${cmd[@]} > "$tmp/repos$1.json"
    cat $tmp/head.txt | grep -Eo 'since=(\d+)'
}

fetch_searches() {
    head="'Authorization: token ${CANAVAREL_ACCESS_TOKEN}'"
    url="'https://api.github.com/search/code?q=filename:.sysl+extension:sysl&$1'"
    # cmd=( curl -H "Authorization: token $CANAVAREL_ENTERPRISE_ACCESS_TOKEN" "https://$edomain/api/v3/search/code?q=filename:.sysl&$1" -D $tmp/head.txt )
    >&2 echo $head
    cmd=( curl -H $head $url -D $tmp/head.txt )
    >&2 echo ">> ${cmd[@]}"
    # ${cmd[@]} > "$tmp/search$1.json"
    eval "curl -H $head $url -D $tmp/head.txt" > "$tmp/search$1.json"
    cat $tmp/head.txt | grep -Eo 'page=(\d+)>; rel="next"' | cut -f1 -d ">"
}

all_repos() {
    rm -rf $tmp/*

    since="since=0"
    while [ "$since" != "" ]
    do
        since=$(fetch_repos $since)
    done

    jq -rs 'reduce .[] as $item ([]; . + $item)' $tmp/*.json > repos.json
}

all_searches() {
    rm -rf $tmp/*
    
    page="page=1"

    while [ "$page" != "" ]
    do
        page=$(fetch_searches $page)
    done

    jq -rs 'reduce .[] as $item ([]; . + $item.items)' $tmp/*.json > searches.json
    # jq '[.[].repository.full_name] | unique | sort' searches.json > searches.json
}

all_searches
