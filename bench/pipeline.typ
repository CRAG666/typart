// The same eight-node pipeline in typart and in fletcher.  Input: with (typart | fletcher).
#set page(width: auto, height: auto, margin: 1cm)

#if sys.inputs.with == "typart" {
  import "/src/typart.typ": *
  flowchart(
    node("raw", (0, 0), [Raw data]), node("clean", (1, 0), [Cleaning]), node("feat", (2, 0), [Features]),
    node("a", (3, 0), [Model A]), node("b", (3, 1), [Model B]), node("ens", (4, 1), [Ensemble]),
    node("rep", (5, 1), [Report]), node("audit", (1, 1), [Audit]),
    edge("raw", "clean", "feat", "a", "ens", "rep"), edge("feat", "b", "ens"),
    edge("clean", "audit", label: [log]),
  )
} else {
  import "@preview/fletcher:0.5.8": diagram, edge, node
  diagram(
    node-stroke: 0.8pt, node-fill: luma(235), spacing: (14mm, 10mm),
    node((0, 0), [Raw data], name: <raw>), node((1, 0), [Cleaning], name: <clean>),
    node((2, 0), [Features], name: <feat>), node((3, 0), [Model A], name: <a>),
    node((3, 1), [Model B], name: <b>), node((4, 1), [Ensemble], name: <ens>),
    node((5, 1), [Report], name: <rep>), node((1, 1), [Audit], name: <audit>),
    edge(<raw>, <clean>, "->"), edge(<clean>, <feat>, "->"), edge(<feat>, <a>, "->"),
    edge(<feat>, <b>, "->"), edge(<a>, <ens>, "->"), edge(<b>, <ens>, "->"), edge(<ens>, <rep>, "->"),
    edge(<clean>, <audit>, "->", [log]),
  )
}
