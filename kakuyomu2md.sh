#!/usr/bin/env bash
#
# kakuyomu2md.sh - Convert Kakuyomu to Markdown
# Copyright (C) 2025 Koichi OKADA. All rights reserved.
# This script is distributed under the MIT License.
#

function check_requirements ()
{
  type fetch.sh >/dev/null 2>&1 || {
    echo "Error: fetch.sh is not found in PATH."
    exit 1
  }

  type jq >/dev/null 2>&1 || {
    echo "Error: jq is not found in PATH."
    exit 1
  }
}

function absolute_url() {
  local url="$1"
  if [[ "$url" =~ ^https?:// ]]; then
    echo "$url"
  else
    echo "${URL_ROOT}${url}"
  fi
}

function fetch () # <url>
{
  fetch.sh -q "$1"
}

function uniform ()
{
  awk ${AWK:+}'
  {
    # 行頭と行末の空白を削除（全角スペースも含む）
    gsub(/^[ \t　]+|[ \t　]+$/, "")

    # 空行のカウント
    if ($0 == "") {
      empty_count++
    } else {
      empty_count = 0
    }

    # 2 行以上の空行を 2 行にまとめる
    if (empty_count <= 2) {
      print
    }
  }
  '
}

function json () # <url> <query>
{
  fetch "$1" \
  | sed -E 's@<script[^>]*>|</script>@\n\0\n@g' \
  | awk '/<script\s[^>]*id="__NEXT_DATA__"[^>]*>/,/<\/script>/' \
  | tail -n-2 | head -n+1 \
  | { [ -z "$2" ] && cat || jq -r "$2"; }
}

check_requirements

(( $# < 1 )) && {
  echo "Usage: $0 <URL>"
  exit 1
}

url="$1"
if [[ ! "$url" =~ ^(https?://[^/]+)/ ]]; then
  echo "Error: Invalid URL: $url"
  exit 1
fi

URL_ROOT="${BASH_REMATCH[1]}"

read -rd $'\0' state < <(json "$url" ".props.pageProps.__APOLLO_STATE__")
read workId < <(json "$url" ".query.workId")
workRef="Work:$workId"
read -rd $'\0' work         < <(<<<"$state" jq -r ".[\"$workRef\"]")
read -rd $'\0' title        < <(<<<"$work"  jq -r ".title")
read -rd $'\0' catchphrase  < <(<<<"$work"  jq -r ".catchphrase")
read -rd $'\0' introduction < <(<<<"$work"  jq -r ".introduction")
read userAccountRef         < <(<<<"$work"  jq -r ".author.__ref")
read author                 < <(<<<"$state" jq -r ".[\"$userAccountRef\"].activityName")
readarray -t tocChapRefs    < <(<<<"$work"  jq -r ".tableOfContents.[].__ref")
printf "# %s\n\n" "$title"
printf "%s 著\n\n" "$author"
printf "%s\n\n" "$catchphrase"
printf "## 概要\n\n"
printf "%s\n\n" "$introduction"

for tocChapRef in "${tocChapRefs[@]}"; do
  read -rd $'\0' tocChap        < <(<<<"$state"   jq -r ".[\"$tocChapRef\"]")
  readarray -t episodeUnionRefs < <(<<<"$tocChap" jq -r ".episodeUnions.[].__ref")
  read chapRef                  < <(<<<"$tocChap" jq -r ".chapter.__ref")
  read -rd $'\0' chap           < <(<<<"$state"   jq -r ".[\"$chapRef\"]")
  read chapTitle                < <(<<<"$chap" jq -r ".title")
  read chapId                   < <(<<<"$chap" jq -r ".id")
  printf "## %s\n\n" "$chapTitle"
  for episodeUnionRef in "${episodeUnionRefs[@]}"; do
    read episodeTitle < <(<<<"$state" jq -r ".[\"$episodeUnionRef\"].title")
    printf "### %s\n\n" "$episodeTitle"
    read episodeId < <(<<<"$state" jq -r ".[\"$episodeUnionRef\"].id")
    url="$URL_ROOT/works/$workId/episodes/$episodeId"

    fetch "$url" \
    | sed -E	's@<p\s+id="p[0-9]+"[^>]*>@\n\0@g;s@</p>@\0\n@g' \
    | grep -E '<p\s+id="p[0-9]+"[^>]*>' \
    | sed -E 's@<p id="p[0-9]+"[^>]*>@@g;s@</p>|<br\s*/?>@\n@g'

    echo
  done
done \
| uniform
