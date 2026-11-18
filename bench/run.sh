#!/bin/sh
# Benchmark.  Needs typst and hyperfine; the fletcher comparison downloads @preview/fletcher once.
#
#   bench/run.sh
#
# Prints costs over an empty document and fails when a budget is exceeded.  Each time is the
# fastest of 20 runs without the system fonts: the scan of the fonts and whatever else the
# machine is doing would drown what is measured.
set -eu
cd "$(dirname "$0")/.."

MS_PER_DIAGRAM=10    # average cost of one diagram
DOUBLING_FACTOR=2.5  # cost of a flowchart when its nodes double

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
failed=0

# fastest wall time in ms of compiling a document; arguments go to typst compile
ms() {
  hyperfine -N -w 2 -r 20 --export-csv "$out/time.csv" "typst compile --ignore-system-fonts --root . $* $out/out.pdf" >/dev/null 2>&1
  awk -F, 'NR == 1 { for (i = 1; i <= NF; i++) if ($i ~ /wall_clock_min/ && !column) column = i } NR == 2 { printf "%.1f", $column * 1000 }' "$out/time.csv"
}
over() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a > b) }'; }

empty=$(ms bench/empty.typ)
echo "empty document: $empty ms"

count=$(grep -c '^  [a-z-]*: ' tests/samples.typ)
each=$(awk -v t="$(ms tests/all.typ)" -v e="$empty" -v n="$count" 'BEGIN { printf "%.1f", (t - e) / n }')
echo "$count diagrams: $each ms each (budget $MS_PER_DIAGRAM)"
over "$each" "$MS_PER_DIAGRAM" && { echo "FAIL over budget"; failed=1; }

for layout in auto grid; do
  previous=
  for n in 25 100 200 400; do
    cost=$(awk -v t="$(ms --input n=$n --input layout=$layout bench/flowchart.typ)" -v e="$empty" 'BEGIN { printf "%.1f", t - e }')
    echo "flowchart, $layout layout, $n nodes: $cost ms"
    [ "$n" = 400 ] && over "$cost" "$(awk -v p="$previous" -v f="$DOUBLING_FACTOR" 'BEGIN { print p * f }')" && {
      echo "FAIL more than ${DOUBLING_FACTOR}x the cost of 200 nodes"; failed=1; }
    previous=$cost
  done
done

avoiding=$(awk -v t="$(ms --input n=25 --input layout=auto --input avoid=1 bench/flowchart.typ)" -v e="$empty" 'BEGIN { printf "%.1f", t - e }')
echo "flowchart, auto layout, 25 nodes, avoid-crossings: $avoiding ms"

typart=$(awk -v t="$(ms --input with=typart bench/pipeline.typ)" -v e="$empty" 'BEGIN { printf "%.1f", t - e }')
if typst compile --ignore-system-fonts --root . --input with=fletcher bench/pipeline.typ "$out/out.pdf" 2>/dev/null; then
  fletcher=$(awk -v t="$(ms --input with=fletcher bench/pipeline.typ)" -v e="$empty" 'BEGIN { printf "%.1f", t - e }')
  echo "eight-node pipeline: typart $typart ms, fletcher $fletcher ms"
else
  echo "eight-node pipeline: typart $typart ms (fletcher not available)"
fi

exit "$failed"
