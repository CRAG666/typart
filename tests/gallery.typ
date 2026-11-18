// The README's gallery: every reference image over its name.  tests/run.sh --update
// compiles it with the names as input.
#set page(width: 42cm, height: auto, margin: 8mm)
#set text(size: 13pt)

#grid(columns: 6, gutter: 8mm, align: center + horizon,
  ..sys.inputs.names.split(",").map(name => stack(spacing: 4mm,
    image("/images/" + name + ".png", width: 100%, height: 4.2cm, fit: "contain"), emph(name))))
