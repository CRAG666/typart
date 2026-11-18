#!/bin/sh
# Tests.  Needs typst and ImageMagick; the icon examples need the Font Awesome 7 Free font.
#
#   tests/run.sh [FILE.md]            every example renders to its reference image, plus checks.typ,
#                                     errors.txt and one layout iteration for all.typ
#   tests/run.sh --update [FILE.md]   rewrite the reference images from the examples
#
# An example is a ```typst block followed by ![..](images/NAME.png); the README is the
# source of every image (FILE.md defaults to it).
set -eu
cd "$(dirname "$0")/.."
update=false
[ "${1:-}" = --update ] && { update=true; shift; }
doc=${1:-README.md}
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
ln -s "$PWD/src" "$PWD/images" "$build/"
failed=0

awk -v dir="$build" '
  /^```typst$/ { inside = 1; code = ""; next }
  /^```$/ { inside = 0; next }
  inside { code = code $0 "\n"; next }
  /^!\[[^]]*\]\(images\/[^)]*\.png\)/ && code != "" {
    name = $0; sub(/^.*\(images\//, "", name); sub(/\.png\).*$/, "", name)
    file = dir "/" name ".typ"
    printf "#import \"/src/typart.typ\": *\n#set page(width: 16cm, height: auto, margin: 4mm)\n#set text(size: 11pt)\n%s", code > file
    close(file); code = ""
    print name > (dir "/names")
  }
' "$doc"

for source in "$build"/*.typ; do
  [ -e "$source" ] || break
  name=$(basename "$source" .typ)
  if ! typst compile --root "$build" --ppi 144 "$source" "$build/$name.raw.png" 2>"$build/log"; then
    echo "FAIL $name: does not compile"; grep -A6 '^error' "$build/log" || true; failed=1; continue
  fi
  background=$(magick "$build/$name.raw.png" -format '%[pixel:p{0,0}]' info:)
  magick "$build/$name.raw.png" -trim +repage -bordercolor "$background" -border 16 "$build/$name.png"
  if $update; then
    cp "$build/$name.png" "images/$name.png"
  elif [ ! -e "images/$name.png" ]; then
    echo "FAIL $name: no reference image (run with --update)"; failed=1
  elif ! magick compare -metric AE "$build/$name.png" "images/$name.png" null: >/dev/null 2>&1; then
    echo "FAIL $name: differs from images/$name.png"; failed=1
  fi
done

if $update && [ "$doc" = README.md ]; then
  typst compile --root . --ppi 72 --input names="$(paste -sd, "$build/names")" tests/gallery.typ images/gallery.png
fi

if [ "$doc" = README.md ]; then
  typst compile --root . tests/checks.typ "$build/checks.pdf" || { echo "FAIL checks.typ"; failed=1; }
  # plain labels lay out in one iteration (content Typst tags, such as bold text, math
  # or images, adds a short second one in any diagram that measures it)
  typst compile --root . --timings "$build/timings.json" tests/all.typ "$build/all.pdf"
  if grep -q '"iter (2)"' "$build/timings.json"; then echo "FAIL all.typ: layout needs a second iteration"; failed=1; fi
  # errors.txt: an expected message, a tab, then the code that must fail with it
  while IFS="$(printf '\t')" read -r message code; do
    printf '#import "/src/typart.typ": *\n%s\n' "$code" > "$build/error.typ"
    if typst compile --root "$build" "$build/error.typ" "$build/error.pdf" 2>"$build/log"; then
      echo "FAIL should not compile: $code"; failed=1
    elif ! grep -qF "$message" "$build/log"; then
      echo "FAIL wrong error for: $code"; echo "  expected: $message"; grep '^error' "$build/log" | head -1; failed=1
    fi
  done < tests/errors.txt
fi

[ "$failed" = 0 ] && echo "ok"
exit "$failed"
