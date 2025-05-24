#!/usr/bin/env bash
#
# narou2md.sh - Convert Narou to Markdown
# Copyright (C) 2025 Koichi OKADA. All rights reserved.
# This script is distributed under the MIT License.
#

function check_requirements ()
{
  type fetch.sh >/dev/null 2>&1 || {
    echo "Error: fetch.sh is not found in PATH."
    exit 1
  }

  type xmllint >/dev/null 2>&1 || {
    echo "Error: xmllint is not found in PATH."
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

function face () # <url>
{
  local url="$1"
   read -r url < <(absolute_url "$url")

  fetch "$url" \
  | grep -E '<h1 ' \
  | sed -E 's/.*<h1[^>]*>([^<]+)<\/h1>.*/# \1/'

  echo

  fetch "$url" \
  | xmllint --html --xpath '//div[@class="p-novel__summary"]/text()' - 2>/dev/null

  echo
}

function get_episode () # <spisode>
{
  if [[ "$1" =~ ^## ]]; then
    printf "\n\n%s\n\n" "$1"
    return
  fi

  local url
  read -r url < <(absolute_url "$1")

  fetch "$url" \
  | grep -E '<p id="La?[0-9]+"|<h1 ' \
  | sed -E 's@<p id="La1"@----\n\n\0@g;s@<h1 @### \0@g;s@</h1>@\n@g;s@</p>@\n@g;s/<[^>]+>//g'
  echo
} 

function get_next_url () # <url>
{
  read -r url < <(absolute_url "$1")
  fetch "$url" \
  | grep -E '<a .*c-pager__item--next' \
  | sed -E 's/.* href="([^"]*)".*/\1/' \
  | head -n 1
}

function get_eplist () # <url>
{
  local eplist url="$1"
  while :; do
    read -r url < <(absolute_url "$url")
    readarray -t eplist < <(
      fetch "$url" \
      | grep -E 'p-eplist__chapter-title|p-eplist__subtitle' \
      | sed -E 's/.* class="[^"]*p-eplist__chapter-title[^"]*"[^>]*>([^<]*).*/## \1/g;s/.* href="([^"]*)".*/\1/' \
    )
    printf "%s\n" "${eplist[@]}"

    ! read url < <(get_next_url "$url") && break
  done
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

readarray -t eplist < <(get_eplist "$url")

{
  face "$url"

  for episode in "${eplist[@]}"; do
    get_episode "$episode"
  done
} | uniform
