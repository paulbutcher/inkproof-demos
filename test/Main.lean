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

private def stackedTest : Except String Unit := do
  let ss := Stacked.areaSeries
  for k in [0:ss.size] do
    for i in [0:(ss.getD k default).size] do
      let sum := (Stacked.levels.take (k + 1)).foldl (fun a l => a + l.getD i 0) 0
      check (Core.Series.stackAt ss k i == some sum) s!"series {k} at point {i} stacks to the sum of the series up to it"
  let bars := Stacked.barSeries 1
  check (bars.all fun s => s.size == Stacked.base.length) "the bar series share their x values"
  check ((bars.getD 0 default).values.any (·.isNone)) "the first bar series keeps its gap"
  for width in [400, 800, 1600] do
    let f := Frame.sized width 400 (-1, 101) (-100, 1200)
    let spacing := (projection f).x 1 - (projection f).x 0
    let rects (d : DisplayList) := d.toList.filterMap fun c => match c.shape with | .rect r => some (c.layer, r) | _ => none
    let axes := rects (axisDisplay f fun _ => (0, 0))
    let bar := (rects (Stacked.barChart #[] 1 f fun _ => (0, 0))).filter fun c => c.1 == 0 && !axes.contains c
    check (!bar.isEmpty) "the first bar series draws bars"
    check (bar.all fun (_, r) => r.x1 - r.x0 > 0 && r.x1 - r.x0 ≤ spacing && r.x1 - r.x0 == spacing * 3 / 5) s!"at width {width} a bar is 60% of the spacing of its centres"

private partial def strokes : Shape → List (Rat × List (List Pt))
  | .strip hw items => [(hw, Item.runs items)]
  | .clipped _ inner => strokes inner
  | _ => []

private def strokeOf (c : Lines.Chart) (l : Lines.Layer) : List (List Pt) :=
  ((c.layerDisplay l).toList.flatMap fun cmd => (strokes cmd.shape).filter (·.1 > 0) |>.flatMap (·.2))

private def linePathsTest : Except String Unit := do
  for c in LinePaths.charts do
    let l ← (c.layers.head?).elim (throw s!"{c.name}: no layer") pure
    let runs := strokeOf c l
    let pts := runs.flatten
    let proj := c.projection l
    let data := (l.data.xs.zip l.data.values).toList.filterMap fun (x, y) => y.map fun y => (proj.x x, proj.y y)
    check (data.all fun (x, y) => pts.any fun p => p.x == x && p.y == y) s!"{c.name}: the line passes through every point"
    if c.name.startsWith "step" then
      check (runs.all fun r => (r.zip r.tail).all fun (a, b) => a.x == b.x || a.y == b.y) s!"{c.name}: every stroke is horizontal or vertical"
    if c.name == "step-after" then
      let dataRuns := (l.data.xs.zip l.data.values).toList.foldr (init := [[]]) fun (x, y) acc =>
        match y, acc with
        | some y, r :: rs => ((proj.x x, proj.y y) :: r) :: rs
        | _, rs => [] :: rs
      check (dataRuns.all fun r => (r.zip r.tail).all fun (a, b) => pts.any fun p => p.x == b.1 && p.y == a.2) s!"{c.name}: a value holds until the next point"

private def gradientsTest : Except String Unit := do
  for c in Gradients.charts do
    for l in c.layers do
      for (g, sh) in [(l.strokeGradient, l.strokeShading (c.projection l)), (l.fillGradient, (l.fillShading (c.projection l)).getD (.flat l.color))] do
        let some g := g | continue
        let stops := g.ordered
        let pos (v : Rat) := match g.axis with | .x => (c.projection l).x v | .y => (c.projection l).y v
        let px (p : Rat) : Pixel := match g.axis with | .x => ⟨p.floor.toNat, 0⟩ | .y => ⟨0, p.floor.toNat⟩
        for (a, b) in stops.zip stops.tail do
          let (pa, pb) := (pos a.1, pos b.1)
          check (pa < pb) s!"{c.name}: stops ascend on the page"
          -- the pixel nearest the midpoint, blended in proportion to where its centre lies between the stops
          let mid := px ((pa + pb) / 2)
          let centre : Rat := (match g.axis with | .x => mid.col | .y => mid.row : Nat) + 1 / 2
          let w := (centre - pa) / (pb - pa)
          if 0 < w && w < 1 && pa ≥ 0 && pb ≥ 0 then
            let got := sh.at mid
            -- a stepped stop's colour holds from its value towards higher values, so away from the plane's order on y
            let want := if !g.discrete then a.2.lerp b.2 w else match g.axis with | .x => a.2 | .y => b.2
            check ((((got.r.toNat : Int) - want.r.toNat).natAbs ≤ 1) && (((got.g.toNat : Int) - want.g.toNat).natAbs ≤ 1) && (((got.b.toNat : Int) - want.b.toNat).natAbs ≤ 1)) s!"{c.name}: colour between stops is their blend, or the lower stop's for a stepped one"

private def axesTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let drawings := axes (AreaFill.frame 1200) measure
  let [bottom, left] := drawings | throw "expected a bottom and a left axis"
  check (!bottom.labels.isEmpty && !left.labels.isEmpty) "both axes keep labels"
  let f := AreaFill.frame 1200
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
  check (LogScales.layers.all fun l => l.data.xs.size ≤ LogScales.times.size) "no server has more samples than times"
  check (LogScales.layers.any fun l => l.data.xs.size < LogScales.times.size) "samples a server did not report are left out"
  check (LogScales.layers.all fun l => l.data.values.all (·.isSome)) "a server's line is bridged across the samples it did not report"
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
  let z := (SparklinesBars.frame |> projection).y 0
  let shade (sh : Shading) (row : Rat) : Color := sh.at ⟨0, (row.floor.toNat)⟩
  check ((shade SparklinesBars.zeroSteps (z - 10)) == SparklinesBars.green && (shade SparklinesBars.zeroSteps (z + 10)) == SparklinesBars.red) "the line and bars are green above zero and red below it"
  check ((shade SparklinesBars.fillGradient (z - 1)).r ≥ 250 && (shade SparklinesBars.fillGradient (z - 1)).b ≥ 250 && (shade SparklinesBars.fillGradient (z + 1)).g ≥ 250 && (shade SparklinesBars.fillGradient (z + 1)).b ≥ 250) "the fill is white at zero"
  check ((shade SparklinesBars.fillGradient ((SparklinesBars.height : Rat) - 1)).r == 255 && (shade SparklinesBars.fillGradient ((SparklinesBars.height : Rat) - 1)).g < 60) "the fill is red at the bottom of the plot"

private def barsTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let charts := GroupedBars.charts.map (·.2) ++ [MultiBars.builds 1, MultiBars.benchmark 1 false, MultiBars.benchmark 1 true]
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
  check ((MultiBars.builds 1).bars.size == 26 && (MultiBars.builds 1).bars.all fun b => b.outline.isSome) "every build has an outlined bar"
  check ((MultiBars.builds 1).bars.any (!·.positive) && (MultiBars.builds 1).bars.any (·.positive)) "durations of both signs are drawn"
  let bench := MultiBars.benchmark 1 false
  let missing := MultiBars.libs.filter (·.interact.isNone) |>.size
  check (bench.bars.size == bench.series.size * MultiBars.libs.size - missing - (MultiBars.libs.filter (·.toggle.isNone)).size) "a library with no measurement has no bar"
  check (bench.lineDisplay.size > 0 && (MultiBars.benchmark 1 true).lineDisplay.size == bench.lineDisplay.size) "the random line is drawn in both layouts"

private def latencyTest : Except String Unit := do
  check (LatencyHistogram.counts.foldl (· + ·) 0 == LatencyHistogram.samples.size) "every latency is counted in a bucket"
  check (LatencyHistogram.columns.size == 100 && LatencyHistogram.columns.all fun c => 200 ≤ c.size && c.size ≤ 500) "each column holds 200 to 500 latencies"
  check (LatencyHistogram.samples.all (25 ≤ ·)) "no latency falls below the 25 ms floor"
  check (LatencyHistogram.counts.foldl max 0 > 0) "the histogram is not empty"

private def heatmapTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  check ((Scatter.clouds 1).size == 4 && (Scatter.clouds 1).all (·.points.size == 10000)) "four clouds of ten thousand points"
  check ((Scatter.scatterChart 1 (Scatter.scatterFrame 1) #[] measure).size > 40000) "every scatter point is drawn"
  check (LatencyHeatmap.columns.all fun c => 200 ≤ c.size && c.size ≤ 500 && c.all (50 ≤ ·)) "each column holds 200 to 500 latencies of at least 5 ms"
  let total := LatencyHeatmap.bucketCells.foldl (fun n c => n + (c.value.map (·.1)).getD 0) 0
  check (total == LatencyHeatmap.columns.foldl (· + ·.size) 0) "every latency is counted in a bucket"
  check (LatencyHeatmap.bucketCells.all fun c => match c.value with | some (n, most) => 0 < n && n ≤ most | none => false) "a bucket's count never exceeds its column's largest"
  check (LatencyHeatmap.sampleCells.size == LatencyHeatmap.columns.foldl (· + ·.size) 0) "a cell for every latency"
  check (HeatmapCells.counts.foldl (· + ·) 0 == HeatmapCells.samples) "every sample falls in a cell"
  check (HeatmapCells.cells.size > 0) "the heatmap is not empty"

private def zoomTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  for c in [Zoom.basic, Zoom.variation] do
    let home := Viewport.View.home c.config
    let zoomed := Viewport.View.step c.config home (.wheel 100 100 4)
    check (zoomed != home) "a wheel notch changes the view"
    check (Viewport.View.step c.config zoomed .reset == home) "reset returns to the home view"
    let layers := c.retain 1
    let (cache, first) := c.commands {} true home measure (c.width, c.height) 1 layers #[]
    let (cache, second) := c.commands cache false zoomed measure (c.width, c.height) 1 layers #[]
    let (_, hidden) := c.commands cache false zoomed measure (c.width, c.height) 1 layers #[true]
    let (_, shownAgain) := c.commands cache false zoomed measure (c.width, c.height) 1 layers #[]
    let uploads (bytes : ByteArray) := ((Gpu.decode bytes.data.toList).getD []).filterMap fun cmd => match cmd.args with
      | [_, .words ws] => if cmd.op == 1 then some ws else none
      | _ => none
    let lines := layers.toList.flatMap (·.words)
    check (lines.all (uploads first).contains) "the first frame uploads every line"
    check (lines.all fun l => !(uploads second).contains l) "a frame under another view uploads no line again"
    check (lines.all fun l => !(uploads hidden).contains l && !(uploads shownAgain).contains l) "hiding a line and showing it again uploads no line again"

private def linkedTest : Except String Unit := do
  check (Linked.syncCharts.length == 3) "sync cursor has three charts"
  check (Linked.syncCharts.all fun (_, c) => c.lines.all fun l => l.xs.size == 1000 && l.ys.size == 1000 && l.xs.back? == some 999) "the synced charts share one x range"
  let whole := Linked.file 1
  check (whole.size == Linked.samples) "the served file holds one byte per sample"
  for (lo, hi) in [(0, 5000), (123, 480), (4990, 6000)] do
    let (first, count) := Linked.windowOf (Float.ofNat lo) (Float.ofNat hi)
    check (first + count ≤ Linked.samples) s!"the window for {lo}..{hi} stays inside the file"
    check (first ≤ lo && first + count ≥ min hi Linked.samples) s!"the window for {lo}..{hi} covers the range"
    let pts := Linked.points 1 first (whole.extract first (first + count))
    check (pts.all fun (x, y) => y == (Linked.sample x.floor.toNat : Nat)) "fetched points hold the samples at their index"
  check ((Linked.windowOf 100 50).2 > 0) "a reversed range still fetches a sample"

private def candlesTest : Except String Unit := do
  let p := Candles.pane
  let n := Candles.candles.size
  check (n == 218 && Candles.candles.all fun c => c.low ≤ c.open_ && c.low ≤ c.close && c.open_ ≤ c.high && c.close ≤ c.high) "every candle's open and close lie between its low and high"
  for (c, i) in Candles.candles.zipIdx do
    let (b, w) := (Candles.body i c, Candles.wick i c)
    check (b.y0 == min (p.row p.left c.open_) (p.row p.left c.close) && b.y1 == max (p.row p.left c.open_) (p.row p.left c.close)) s!"candle {i}: the body spans open to close"
    check (w.y0 == p.row p.left c.high && w.y1 == p.row p.left c.low) s!"candle {i}: the wick spans high to low"
    check (w.y0 ≤ b.y0 && b.y1 ≤ w.y1) s!"candle {i}: the body lies within the wick"
    check (p.plot.x0 ≤ b.x0 && b.x1 ≤ p.plot.x1 && b.x1 - b.x0 ≤ 20) s!"candle {i}: the body lies within the plot and is at most 20 pixels wide"
    check ((Candles.volumeBar i c).y1 == p.plot.y1) s!"candle {i}: the volume bar stands on the bottom of the plot"
  check ((List.range (n - 1)).all fun i => (Candles.body i (Candles.candles.getD i ⟨0, 0, 0, 0, 0, 0⟩)).x1 < (Candles.body (i + 1) (Candles.candles.getD (i + 1) ⟨0, 0, 0, 0, 0, 0⟩)).x0) "neighbouring bodies do not touch"
  let fills := Candles.candles.zipIdx.map fun (c, i) =>
    (decide (c.close < c.open_), match ((Candles.commands i c).getD 2 ⟨0, Candles.black, .rect ⟨0, 0, 0, 0⟩⟩).color with
      | .flat col => col == (if c.close < c.open_ then Candles.bearish else Candles.bullish)
      | _ => false)
  check (fills.all (·.2)) "a candle is red where the price fell and green where it rose"
  check (fills.any (·.1) && fills.any (!·.1)) "both rising and falling days are drawn"

private def boxesTest : Except String Unit := do
  for c in Boxes.charts do
    let p := c.pane
    check (c.boxes.size == Boxes.frameworks.size) s!"{c.name}: a box for each framework"
    check (c.boxes.all fun b => b.min ≤ b.q1 && b.q1 ≤ b.median && b.median ≤ b.q3 && b.q3 ≤ b.max) s!"{c.name}: the quartiles lie in order within the whiskers"
    check (c.boxes.all fun b => b.outliers.all fun v => v < b.min || b.max < v) s!"{c.name}: outliers lie beyond the whiskers"
    check (c.boxes.any (!·.outliers.isEmpty)) s!"{c.name}: some runs are outliers"
    check ((c.boxes.toList.zip (c.boxes.toList.drop 1)).all fun (a, b) => a.median ≤ b.median) s!"{c.name}: boxes run from the fastest median"
    for (b, i) in c.boxes.zipIdx do
      let r := Boxes.body p i b
      let m := Boxes.medianBar p i b
      check (r.y0 ≤ (m.y0 + m.y1) / 2 && (m.y0 + m.y1) / 2 ≤ r.y1 && r.y0 == p.row p.left b.q3 && r.y1 == p.row p.left b.q1) s!"{c.name} {b.name}: the median lies within the box, which spans the quartiles"
      check (p.plot.y0 ≤ p.row p.left b.max && p.row p.left b.min ≤ p.plot.y1 && p.row p.left b.max ≤ r.y0 && r.y1 ≤ p.row p.left b.min) s!"{c.name} {b.name}: the whiskers reach beyond the box within the plot"
      check (p.plot.x0 ≤ r.x0 && r.x1 ≤ p.plot.x1) s!"{c.name} {b.name}: the box lies within the plot"
  let b := Boxes.Box.ofRuns "x" #[1, 2, 3, 4, 5, 6, 7, 8, 9, 100]
  check (b.median == 11 / 2 && b.outliers == #[100] && b.max == 9 && b.min == 1) "a run far from the rest is an outlier and not a whisker"

private def timelineTest : Except String Unit := do
  for c in Timeline.charts do
    let f := c.frame
    check (c.rows.size == 3) s!"{c.name}: three rows"
    for (r, i) in c.rows.zipIdx do
      let rects := r.spans.map (c.rect i)
      check ((rects.toList.zip (rects.toList.drop 1)).all fun (a, b) => a.x1 ≤ b.x0) s!"{c.name} {r.name}: bars do not overlap"
      check (r.spans.all fun s => (c.rect i s).x0 == c.xMap s.start && (c.rect i s).x1 == c.xMap s.stop) s!"{c.name} {r.name}: each bar covers its state's interval"
      check (r.spans.all fun s => s.start < s.stop) s!"{c.name} {r.name}: every interval has a length"
      check (rects.all fun b => f.left ≤ b.x0 && b.x1 ≤ f.right && f.top ≤ b.y0 && b.y1 ≤ f.bottom) s!"{c.name} {r.name}: bars lie within the plot"
    check ((List.range 2).all fun i => (c.lane i).2 ≤ (c.lane (i + 1)).1) s!"{c.name}: rows do not overlap"
  let [spans, periodic, letters] := Timeline.charts | throw "expected three charts"
  check (spans.rows.all fun r => r.spans.size ≥ 3) "the first chart holds several states for each device"
  check ((periodic.rows.map (·.spans.size)).toList == [29, 30, 29]) "a missing sample leaves a gap in the periodic chart"
  check (periodic.rows.all fun r => r.spans.all fun s => s.stop - s.start == 9 * Timeline.hour / 10) "periodic bars are equally wide"
  check ((letters.rows.getD 2 ⟨"", #[]⟩).spans.size == 4) "the gaps in a series of flags have no bars"

private def annotationsTest : Except String Unit := do
  let c := Annotations.chart
  let f := c.frame
  check (c.marks.length == 2) "two notes"
  let zoomed := { f with xs := (6, 12) }
  for m in c.marks do
    for g in [f, zoomed] do
      let (a, b) := Zoom.Mark.columns g m
      check (g.xs.1 + (a - g.left) / (g.right - g.left) * (g.xs.2 - g.xs.1) == m.start) s!"{m.label}: starts at the data position it names"
      check (g.xs.1 + (b - g.left) / (g.right - g.left) * (g.xs.2 - g.xs.1) == m.stop) s!"{m.label}: ends at the data position it names"
    check ((Zoom.Mark.columns zoomed m).1 != (Zoom.Mark.columns f m).1) s!"{m.label}: moves with the chart when it zooms"
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  check ((c.markTexts f measure).length == 2 && (c.markTexts { f with xs := (20, 25) } measure).isEmpty) "a note outside the range has no label"
  check (c.marks.all fun m => (Zoom.Mark.commands { f with xs := (20, 25) } measure m).isEmpty || m.stop ≥ 20) "a note outside the range draws nothing"
  check (c.markData.any fun cmd => match cmd.shape with | .rect r => r.x0 == 9.3 && r.x1 == 18.5 | _ => false) "the shaded range is a rectangle over its data interval"

private def calendarTimeTest : Except String Unit := do
  let (london, chicago) := (← CalendarTime.london, ← CalendarTime.chicago)
  for (z, change, before, after) in [(london, 1553994000, 0, 3600), (london, 1572138000, 3600, 0),
      (chicago, 1552204800, -21600, -18000), (chicago, 1572764400, -18000, -21600)] do
    check (z.offset (change - 1) == before && z.offset change == after) s!"{z.name}: the offset changes at the instant {change}"
  for s in ← CalendarTime.dstSpecs do
    let ts := s.tickTimes
    check (!ts.isEmpty && ts.length == s.tickLabels.length) s!"{s.name}: every tick has a label"
    check ((ts.zip ts.tail).all fun (a, b) => a < b) s!"{s.name}: ticks and labels run in increasing order of instant"
    check (ts.all fun t => Rat.toFloat s.xs.1 ≤ t && t ≤ Rat.toFloat s.xs.2) s!"{s.name}: ticks lie within the range"
    if s.step ≥ 3600 then
      check (ts.all fun t => (t.toInt64.toInt + s.zone.offset t.toInt64.toInt) % 3600 == 0) s!"{s.name}: hourly ticks sit on the zone's local hours"
    if s.step ≥ 86400 then
      check (ts.all fun t => (t.toInt64.toInt + s.zone.offset t.toInt64.toInt) % 86400 == 0) s!"{s.name}: day ticks sit at the zone's local midnight"
  let m ← CalendarTime.monthSpec 1
  let days := m.tickTimes.map fun t => (Core.Calendar.civilFromDays ((t.toInt64.toInt + m.zone.offset t.toInt64.toInt) / 86400)).2.2
  check (days.length == 36 && days.all (· == 1)) "month ticks fall on the first of each month"
  check (m.values.size == 36 && m.values.getD 0 0 == 5 && m.values.all fun v => 0 ≤ v && v ≤ 10) "the levels are 0 to 10 with a first of 5"

private def arcsinhTest : Except String Unit := do
  let vs := ArcsinhScales.values
  check (vs.size == 111 && vs.getD 55 1 == 0 && (List.range 55).all fun i => vs.getD i 0 == -(vs.getD (110 - i) 0)) "the values mirror about a zero in the middle"
  check ((vs.toList.zip vs.toList.tail).all fun (a, b) => a < b) "the values increase"
  for k in [-3, -1, 0, 2, 3] do
    check (ArcsinhScales.threshold k * (10 : Rat) ^ 3 == (10 : Rat) ^ (k + 3).toNat) s!"the threshold for position {k} is ten to the {k}"
    for v in vs do
      let y := ArcsinhScales.yPixel k (Rat.toFloat v)
      let back := ArcsinhScales.yValue k y
      check ((back - Rat.toFloat v).abs ≤ 1e-6 * (1 + (Rat.toFloat v).abs)) s!"position {k}: the pixel of {Rat.toFloat v} maps back to {back}"
      check (ArcsinhScales.frame.top.toFloat ≤ y && y ≤ ArcsinhScales.frame.bottom.toFloat) s!"position {k}: {Rat.toFloat v} lies within the plot"
    check ((vs.toList.zip vs.toList.tail).all fun (a, b) => ArcsinhScales.yPixel k (Rat.toFloat a) > ArcsinhScales.yPixel k (Rat.toFloat b)) s!"position {k}: larger values are higher on the page"

private def customScalesTest : Except String Unit := do
  let xs := CustomScales.times
  check (xs.size == 199 && (xs.toList.zip xs.toList.tail).all fun (a, b) => a < b) "the x values increase"
  for ((a, b), c) in (CustomScales.lower.values.zip CustomScales.fitted.values).zip CustomScales.upper.values do
    let (a, b, c) := (a.getD 0, b.getD 0, c.getD 0)
    check (0 ≤ a && a ≤ b && b ≤ c && c ≤ 1) "the lower bound, the fit and the upper bound are ordered probabilities"
  for (x, y) in xs.toList.zip (CustomScales.fitted.values.toList.map (·.getD 0)) do
    let want := 1 - Float.exp (-((Rat.toFloat x / 30) ^ 2))
    check ((Rat.toFloat y - want).abs ≤ 1e-9) s!"the fit at {Rat.toFloat x} is a Weibull distribution of scale 30 and shape 2"
  let w := CustomScales.specs.getD 2 ⟨"", false, .linear⟩
  for v in [0.00001, 0.01, 0.5, 0.9, 0.999999] do
    let back := w.yValue (w.yPixel v)
    check ((back - v).abs ≤ 1e-9 * v) s!"the Weibull scale maps {v} and its pixel back to {back}"
  let px := xs.toList.map fun x => w.xPixel (Rat.toFloat x)
  let py := (CustomScales.fitted.values.toList.map fun y => w.yPixel (Rat.toFloat (y.getD 0)))
  let slopes := (px.zip py).zip ((px.zip py).tail) |>.map fun ((x0, y0), (x1, y1)) => (y1 - y0) / (x1 - x0)
  check (slopes.all fun m => (m - slopes.headD 0).abs ≤ 1e-3 * (slopes.headD 0).abs) "the fitted curve is a straight line on log x against the Weibull scale"
  check (CustomScales.weibullTicks.length == CustomScales.weibullLabels.length) "each Weibull tick has a label"

private def faint (c : Command) : Bool := match c.color with | .flat ⟨_, _, _, a⟩ => a == 18 | _ => false

private def parityTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let f := Frame.sized 400 300 (0, 100) (0, 100)
  let positive (d : DisplayList) := d.toList.filterMap fun c => match c.shape with | .strip hw _ => if hw > 0 then some (hw, c) else none | _ => none
  let axes := positive (axisDisplay f measure)
  check (!axes.isEmpty && axes.all fun (hw, c) => hw == 1 && faint c) "an axis draws only faint ticks and gridlines, each two pixels wide, and no axis line"
  let ticks := (Axes.linearLabels 0 100).length
  check (axes.length == 4 * ticks) "each tick of each axis has a tick mark and a gridline, and nothing else is drawn"
  for (name, d) in [("axis control", AxisControl.chart measure),
      ("log scales 2", (LogScales2.specs.head?.map (·.chart #[] measure)).getD #[]),
      ("points", (Points.multiParts Points.multi.frame).foldl (· ++ ·) #[]),
      ("points, single", (Points.singleParts true Points.single.frame).foldl (· ++ ·) #[])] do
    let strokes := positive d |>.filter fun (_, c) => !faint c
    check (!strokes.isEmpty && strokes.all fun (hw, _) => hw == 1 / 2) s!"{name}: the series is one pixel wide, uPlot's default"

def main (args : List String) : IO UInt32 :=
  runTests [⟨"area fill", areaFillTest⟩, ⟨"area fill axes", axesTest⟩, ⟨"log scales", logScalesTest⟩, ⟨"log scales 2", logScales2Test⟩, ⟨"axis control", axisControlTest⟩, ⟨"time series pages", linesTest⟩, ⟨"million", millionTest⟩, ⟨"server events", serverEventsTest⟩, ⟨"gallery B", galleryBTest⟩, ⟨"bars", barsTest⟩, ⟨"latency histogram", latencyTest⟩, ⟨"heatmaps", heatmapTest⟩, ⟨"zoom", zoomTest⟩, ⟨"linked", linkedTest⟩, ⟨"candlestick", candlesTest⟩, ⟨"box and whisker", boxesTest⟩, ⟨"timeline", timelineTest⟩, ⟨"annotations", annotationsTest⟩, ⟨"stacked series", stackedTest⟩, ⟨"line paths", linePathsTest⟩, ⟨"gradients", gradientsTest⟩, ⟨"calendar time", calendarTimeTest⟩, ⟨"arcsinh scales", arcsinhTest⟩, ⟨"custom scales", customScalesTest⟩, ⟨"parity with uPlot", parityTest⟩, platformTest (args.contains "--expect-wasm")]
