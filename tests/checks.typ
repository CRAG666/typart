// Properties every diagram must keep; compiling this file is the test.
#import "/src/typart.typ": *
#import "/src/common.typ": _contrast, _luminance, _on, _theme

#set text(size: 10pt)

// the palette stays distinct in greyscale
#let luminances = palette.map(_luminance).sorted()
#assert(luminances.windows(2).all(((a, b)) => b - a >= 0.1), message: "palette colours closer than 0.1 in luminance: "
  + repr(luminances))

// text on any theme fill reaches 4.5:1, on a light and on a dark page
#context for (ink, surface) in ((black, white), (white, rgb("#1e1e2e"))) {
  let t = _theme("checks.typ", (ink: ink, surface: surface), arguments())
  for fill in (..t.palette, t.accent, t.panel, t.muted, t.ink, t.surface) {
    assert(_contrast(_on(t, fill), fill) >= 4.5, message: "text on " + repr(fill) + " is below 4.5:1")
  }
}

// no diagram overflows a paper column or an A4 text block
#import "samples.typ": samples, three
#let wide = ("contrastive", "pill-steps", "process")  // several columns of boxes: wider than a paper column by nature
#context for (name, sample) in samples {
  for container in (8.4cm, 16cm).slice(if name in wide { 1 } else { 0 }) {
    assert(measure(sample, width: container).width <= container + 0.1pt, message: name + " overflows " + repr(container))
  }
}

// `themed` covers every diagram, and a theme passed to one call adds to it
#let ta = themed(accent: red)
#assert(samples.keys().all(name => name in ta), message: "themed() lacks "
  + samples.keys().filter(name => name not in ta).join(", "))
#let (flow, flowchart, node, edge) = ta
#flow(three, theme: (corner-radius: 0pt), accent: blue)
#flowchart(node("a", [A]), node("b", [B]), edge("a", "b"))

// a `fill` mark colours its list item and leaves the label, or the number, as written
#import "/src/common.typ": _items
#let marked = _items("test", [
  / Train: 70
  / Test: 30 #fill(red)
], (blue,), fields: ("label", "value"), numbers: ("value",))
#assert(marked.map(it => (it.value, it.fill)) == ((70, blue), (30, red)), message: "fill mark: got " + repr(marked))
