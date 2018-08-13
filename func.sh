#!/bin/bash

set -- "${1:-$(</dev/stdin)}" "${@:2}"

main() {
  check_args "$@"
  local gitlaburl=$1
  local project=$2
  local issue=$3

  local json=$(get_html $gitlaburl $project $issue)
  
  echo $json| jq -cr '.[] .notes[0] .created_at' > /tmp/dates
  echo $json| jq -cr '.[] .notes[0] .author .name' > /tmp/author
  echo $json| jq -cr '.[] .notes[0] .note' > /tmp/note
  echo $json| jq -cr '.[] .notes[0] .id' > /tmp/id
  cat > /tmp/feed <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>
  <title>Gitlab Issue #$issue RSS feed</title>
  <link>$gitlaburl$project/issues/$issue</link>
  <description>Update on issue #$issue</description>
EOF
  while read -u 3 -r date && read -u 4 -r author && read -u 5 -r note && read -u 6 -r id; do
    dateRfc=`date -R -d $date`
    cat >> /tmp/feed <<EOF
  <item>
    <title>Note from $author</title>
    <link>$gitlaburl$project/issues/$issue#note_$id</link>
    <description>$note</description>
    <pubDate>$dateRfc</pubDate>
    <author>$author</author>
  </item>
EOF
  done 3</tmp/dates 4</tmp/author 5</tmp/note 6</tmp/id
  cat >> /tmp/feed <<EOF
</channel>

</rss>
EOF
  cat /tmp/feed
}

get_html() {
  local gitlaburl=$1
  local project=$2
  local issue=$3
  local url=$gitlaburl$project/issues/$issue/discussions.json

  curl \
    --silent \
    --location \
    "$url"
}

check_args() {
  if (($# != 3)); then
    echo "Error:
    3 arguments must be provided - $# provided.
  
    Usage:
      gitlab-rss https://gitlab.com/ gitlab-org/gitlab-ce 24030
      
Aborting."
    exit 1
  fi
}

main $1
