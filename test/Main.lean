/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import InkproofTools.Test.Harness
import InkproofTools.Test.Platform

open InkproofTools.Test Inkproof.Demos Inkproof.Scene Inkproof

private def areaFillTest : Except String Unit := do
  for seed in [1, 2, 3] do
    let s := AreaFill.series seed 30
    check (s.xs == (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)) s!"series {seed} runs over 1..30"
    check (s.values.all fun v => v.any fun y => -10 ≤ y && y ≤ 10) s!"series {seed} stays within -10..10"
  check (AreaFill.values 1 12 == #[-8, 9, 3, 7, -3, 0, -2, 9, 3, 3, -10, -3]) "series 1 differs from the recorded values, so a platform draws other data"
  check (AreaFill.values 2 12 == #[1, 5, 5, -9, -7, 0, -9, 9, -9, 4, -6, -3]) "series 2 differs from the recorded values, so a platform draws other data"

private def axesTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let drawings := axes AreaFill.frame measure
  let [bottom, left] := drawings | throw "expected a bottom and a left axis"
  check (!bottom.labels.isEmpty && !left.labels.isEmpty) "both axes keep labels"
  let f := AreaFill.frame
  check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) "left labels lie within the plot's height"
  check (bottom.labels.all fun l => l.anchor.x ≥ f.left && l.anchor.x ≤ f.right) "bottom labels lie within the plot's width"
  check (left.labels.length ≥ 5) "the left axis keeps most of its labels"

private def logScales2Test : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  for spec in LogScales2.specs do
    let f := spec.frame
    check (spec.data.xs.all fun x => spec.xs.1 ≤ x && x ≤ spec.xs.2) s!"{spec.name}: points lie within the x range"
    check (spec.data.values.all fun v => v.all fun y => spec.kind == .linear || (0 < y && spec.ys.1 ≤ y && y ≤ spec.ys.2)) s!"{spec.name}: a log chart holds only values its scale can place"
    let [_, left] := spec.axes measure | throw s!"{spec.name}: expected two axes"
    check (!left.labels.isEmpty) s!"{spec.name}: the y axis keeps labels"
    check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) s!"{spec.name}: y labels lie within the plot"
  let signed := LogScales2.specs.find? (·.name == "signed") |>.map (·.data.values)
  check (signed.any fun vs => vs.any (·.isNone) && vs.any (·.isSome)) "non-positive values are gaps, not bridged or dropped wholesale"

private def logScalesTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  check (!LogScalesSource.times.isEmpty && LogScalesSource.players.all (·.size == LogScalesSource.times.size)) "every literal of the Log Scales data parses and has a sample per time"
  check (LogScales.layers.length == 12) "one line per server"
  check (LogScales.layers.all fun l => l.data.xs.size == LogScales.times.size) "every server has every time"
  check (LogScales.layers.any fun l => l.data.values.any (·.isNone)) "samples a server did not report are gaps"
  for spec in LogScales.specs do
    let f := spec.frame
    check (LogScales.layers.all fun l => l.data.values.all fun v => v.all fun y => spec.ys.1 ≤ y && y ≤ spec.ys.2) s!"{spec.name}: every sample lies within the y range"
    let [bottom, left] := spec.axes measure | throw s!"{spec.name}: expected two axes"
    check (!bottom.labels.isEmpty && !left.labels.isEmpty) s!"{spec.name}: both axes keep labels"
    check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) s!"{spec.name}: y labels lie within the plot"

private def millionTest : Except String Unit := do
  let exts := Million.columnExtents Million.pyramid
  check (exts.size == Million.columns) "one extent per column"
  check (Million.shownCount (Million.inkproofShown exts) == Million.spikes.size) "Inkproof shows every spike"
  check (Million.shownCount Million.naiveShown < Million.spikes.size) "naive decimation loses a spike"

private def serverEventsTest : Except String Unit := do
  for f in ServerEvents.series do
    let e := ServerEvents.extents f
    check (e.size == ServerEvents.columns) "one extent per column"
    check (ServerEvents.drawnHighest e == ServerEvents.highest f) "the envelope reaches the highest value of the data"
    check (ServerEvents.highest f > 0) "the series is not flat"

private def axisControlTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  check (AxisControl.series.xs.size == AxisControl.n) "the series has every point"
  check (AxisControl.series.values.all fun v => v.all fun y => -50 ≤ y && y ≤ 50) "the series stays within the fixed y range"
  let [_, right] := AxisControl.axes measure | throw "expected two axes"
  check (!right.labels.isEmpty) "the right axis keeps labels"
  check (right.labels.all fun l => l.anchor.x ≥ AxisControl.frame.right) "the right axis labels lie right of the plot"

private def linesTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let charts := MissingData.charts ++ HighLowBands.charts ++ PathGapClip.charts
  for c in charts do
    let f := c.frame
    check (c.layers.all fun l => l.data.xs.all fun x => c.xs.1 ≤ x && x ≤ c.xs.2) s!"{c.name}: points lie within the x range"
    check (c.layers.all fun l => l.data.values.all fun v => v.all fun y => (if l.onRight then (c.right.getD c.left) else c.left).range.1 ≤ y && y ≤ (if l.onRight then (c.right.getD c.left) else c.left).range.2) s!"{c.name}: points lie within their y range"
    let axes := c.axes measure
    check (axes.length == (if c.right.isSome then 3 else 2)) s!"{c.name}: one axis per side"
    for a in axes do
      check (!a.labels.isEmpty) s!"{c.name}: every axis keeps labels"
    match axes with
    | bottom :: left :: _ =>
      check (bottom.labels.all fun l => l.anchor.x ≥ f.left && l.anchor.x ≤ f.right) s!"{c.name}: x labels lie within the plot"
      check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) s!"{c.name}: y labels lie within the plot"
    | _ => throw s!"{c.name}: expected axes"
  let present (s : Core.Series Rat Rat) := (s.values.filter (·.isSome)).size
  check (present MissingData.cpuSeries = 200 - 6 ∧ present MissingData.ramSeries = 200 - 6) "missing samples are gaps, not dropped or filled"
  check (HighLowBands.meanSeries.values.getD 364 none == some 38 ∧ HighLowBands.meanSeries.values.getD 305 (some 0) == none) "the mean has its own gaps"
  let gap := MissingData.gaps.layers.head?.map (·.segments.numSegments)
  check (gap == some 2) "samples further apart than the step are not joined"

private def galleryBTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let f := Scatter.bubbleFrame
  check (Scatter.regions.all fun r => r.bubbles.all fun b =>
    let (lo, hi) := if r.onRight then Scatter.rightRange else f.ys
    f.xs.1 ≤ b.x && b.x ≤ f.xs.2 && lo ≤ b.y && b.y ≤ hi) "bubbles lie within the ranges of their axes"
  let sizes := (Scatter.regions.toArray.flatMap (·.bubbles)).map (·.size)
  check (sizes.all fun a => sizes.all fun b => a ≤ b || Scatter.radius b Scatter.maxSize ≤ Scatter.radius a Scatter.maxSize) "a bigger bubble never has a smaller radius"
  check (sizes.all fun a => 2 * Scatter.radius a Scatter.maxSize ≤ 60) "no bubble is wider than 60 pixels"
  let [_, left, right] := Scatter.bubbleAxes f measure | throw "expected three axes"
  check (right.labels.all fun l => l.anchor.x ≥ f.right && left.labels.all fun l => l.anchor.x ≤ f.left) "y labels lie outside the plot"
  check (StocksSource.stocks.all fun s => s.closeCents.size == s.volume.size && s.volume.size > 1) "every stock has a close and a volume for each record"
  check ((Sparklines.named? "AAPL-close").isSome && (Sparklines.named? "AAPL-open").isNone && (Sparklines.named? "XXXX-close").isNone) "sparklines are found by symbol and kind"
  for s in StocksSource.stocks do
    for close in [true, false] do
      let vals := Sparklines.values s close
      let f := Sparklines.frame vals
      check (vals.all fun v => f.ys.1 < v && v < f.ys.2) s!"{s.symbol}: the sparkline's range holds its values with room to spare"
  for dl in [SparklinesBars.chartSplit, SparklinesBars.chartColored] do
    check (dl.all fun c => match c.shape with
      | .rect r => 0 ≤ r.x0 && r.x1 ≤ SparklinesBars.width && 0 ≤ r.y0 && r.y1 ≤ SparklinesBars.height
      | _ => true) "bars are cut off at the edge of the canvas"

private def barsTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let charts := GroupedBars.charts.map (·.2) ++ [MultiBars.builds, MultiBars.benchmark false, MultiBars.benchmark true]
  for c in charts do
    let p := c.plot
    let inside (r : Scene.Rect) := p.x0 ≤ min r.x0 r.x1 && max r.x0 r.x1 ≤ p.x1 && p.y0 ≤ min r.y0 r.y1 && max r.y0 r.y1 ≤ p.y1
    check (c.bars.all (inside ·.rect)) s!"{c.groups}: every bar lies within the plot"
    let present := c.series.foldl (fun n s => n + (s.values.filter (·.isSome)).size) 0
    if !c.stacked then
      check (c.bars.size == present) s!"{c.groups}: a bar for each present value and none for a missing one"
    else
      let labelled := c.bars.filterMap (·.label)
      let totals := (List.range c.groups.size).map fun g => c.series.foldl (fun t s => t + ((s.values.getD g none).getD 0)) 0
      check (labelled.toList == totals) s!"{c.groups}: a stack is labelled with its total"
    let blocks := (List.range c.groups.size).map c.block
    check (blocks.zip blocks.tail |>.all fun ((s, l), (s', _)) => s + l ≤ s') s!"{c.groups}: groups do not overlap"
    let axes := c.axes measure
    check (axes.length == 2 && axes.all (!·.labels.isEmpty)) s!"{c.groups}: both axes keep labels"
  check (MultiBars.builds.bars.size == 26 && MultiBars.builds.bars.all fun b => b.outline.isSome) "every build has an outlined bar"
  check (MultiBars.builds.bars.any (!·.positive) && MultiBars.builds.bars.any (·.positive)) "durations of both signs are drawn"
  let bench := MultiBars.benchmark false
  let missing := MultiBars.libs.filter (·.interact.isNone) |>.size
  check (bench.bars.size == bench.series.size * MultiBars.libs.size - missing - (MultiBars.libs.filter (·.toggle.isNone)).size) "a library with no measurement has no bar"
  check (bench.lineDisplay.size > 0 && (MultiBars.benchmark true).lineDisplay.isEmpty) "the random line is drawn across, not down"

private def latencyTest : Except String Unit := do
  check (LatencyHistogram.counts.foldl (· + ·) 0 == LatencyHistogram.samples.size) "every latency is counted in a bucket"
  check (LatencyHistogram.columns.size == 100 && LatencyHistogram.columns.all fun c => 200 ≤ c.size && c.size ≤ 500) "each column holds 200 to 500 latencies"
  check (LatencyHistogram.samples.all (25 ≤ ·)) "no latency falls below the 25 ms floor"
  check (LatencyHistogram.counts.foldl max 0 > 0) "the histogram is not empty"

def main (args : List String) : IO UInt32 :=
  runTests [⟨"area fill", areaFillTest⟩, ⟨"area fill axes", axesTest⟩, ⟨"log scales", logScalesTest⟩, ⟨"log scales 2", logScales2Test⟩, ⟨"axis control", axisControlTest⟩, ⟨"time series pages", linesTest⟩, ⟨"million", millionTest⟩, ⟨"server events", serverEventsTest⟩, ⟨"gallery B", galleryBTest⟩, ⟨"bars", barsTest⟩, ⟨"latency histogram", latencyTest⟩, platformTest (args.contains "--expect-wasm")]
