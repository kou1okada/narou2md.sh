# webnovelutils - Convert web novel to Markdown

This script is convert [Narou](https://syosetu.com/) and [Kakuyomu](https://kakuyomu.jp/) to Markdown.

## Requires

### General utilities

* wget
* xmllint (it's provided by the libxml2-utils package)
* jq

### My utilities

* [hhs.bash](https://github.com/kou1okada/hhs.bash)
* [fetch.sh](https://github.com/kou1okada/fetch.sh)

## Usage

### narou2md.sh

```sh
narou2md.sh <url>
```

`<url>` rule is probably `https://ncode.syosetu.com/$NCODE`.


### kakuyomu2md.sh

```sh
kakuyomu2md.sh <url>
```

`<url>` rule is probably `https://kakuyomu.jp/works/$workId`.

## Convert from Markdown to EPUB

Use pandoc.

```sh
TITLE="title"
AUTHOR="author"
SRC="$TITLE.md"
DST="${SRC%.*}.epub"
pandoc "$SRC" \
  -o "$DST" \
  --metadata title="$TITLE" \
  --metadata author="$AUTHOR"
```

## Register to Kindle personal document

* [Send to Kindle](https://www.amazon.co.jp/sendtokindle)


## License

* The MIT license
