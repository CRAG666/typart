// A flowchart of `n` nodes: a binary tree laid out automatically, or a chain on a
// 10-column grid.  Inputs: n, layout (auto | grid), avoid (any value turns avoid-crossings on).
#import "/src/typart.typ": *
#set page(width: auto, height: auto, margin: 1cm)

#let n = int(sys.inputs.n)
#if sys.inputs.at("layout", default: "auto") == "auto" {
  flowchart(avoid-crossings: "avoid" in sys.inputs, ..range(n).map(i => node(str(i), [Node #i])),
    ..range(1, n).map(i => edge(str(calc.quo(i, 2)), str(i))))
} else {
  flowchart(..range(n).map(i => node(str(i), (calc.rem(i, 10), calc.quo(i, 10)), [Node #i])),
    ..range(n - 1).map(i => edge(str(i), str(i + 1))))
}
