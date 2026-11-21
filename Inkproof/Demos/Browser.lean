/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Axis
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Frame
import Inkproof.Demos.Bars
import Inkproof.Web.Access
import Inkproof.Web.Host.Console
import Lasm.JS

namespace Inkproof.Demos.Browser

open Inkproof.Web Inkproof.Web.Host Inkproof.Scene Inkproof.Axis Lasm.JS

private def randomSeed : IO Nat := do
  let r ← (← (← global).get "Math").callMethod "random" #[] Float
  pure (r * 4294967296).toUInt64.toNat

/-- The seed of the page's random data: the `seed` query parameter if it is a natural number, otherwise a fresh random one. A malformed value is logged and ignored. -/
def seed : IO Nat := do
  let g ← global
  let params ← (← g.get "URLSearchParams").new #[toJS (← (← g.get "location").get "search" String)]
  match ← params.callMethod "get" #[toJS "seed"] (Option String) with
  | none => randomSeed
  | some text =>
    match text.toNat? with
    | some n => pure n
    | none =>
      log .warn "seed is not a natural number, using a random one" [("seed", text)]
      randomSeed

/-- The width of the window in CSS pixels. -/
def windowWidth : IO Nat := do
  let w ← (← global).get "innerWidth" Float
  pure w.round.toUInt64.toNat

/-- The labels of a bottom axis followed by those of a left axis. -/
def tickLabels (axes : List AxisDrawing) : Array Label :=
  (axes.zip [Side.bottom, Side.left]).toArray.flatMap fun (a, side) => Label.ofDrawing side a

theorem tickLabels_eq (axes : List AxisDrawing) :
    tickLabels axes = (axes.zip [Side.bottom, Side.left]).toArray.flatMap fun (a, side) => Label.ofDrawing side a := rfl

/-- A colour as CSS writes it. -/
def cssColor (c : Color) : String := s!"rgb({c.r},{c.g},{c.b})"

theorem cssColor_eq (c : Color) : cssColor c = s!"rgb({c.r},{c.g},{c.b})" := rfl

/-- A series as the legend reads it, a missing value being not a number. -/
def traceOf (name : String) (color : Color) (hidden : Bool) (s : Core.Series Rat Rat) : Trace :=
  { name, color := cssColor color, hidden, xs := s.xs.map Rat.toFloat, ys := s.values.map fun y => (y.map Rat.toFloat).getD (0 / 0) }

theorem traceOf_eq (name : String) (color : Color) (hidden : Bool) (s : Core.Series Rat Rat) : traceOf name color hidden s =
    { name, color := cssColor color, hidden, xs := s.xs.map Rat.toFloat, ys := s.values.map fun y => (y.map Rat.toFloat).getD (0 / 0) } := rfl

/-- What a chart drawn in `f` tells the page: the legend's traces, and a plot of fixed ranges for the cursor to move over. -/
def accessOf (name : String) (f : Frame) (traces : Array Trace) : Access :=
  { name, series := traces.map fun _ => "line", points := (traces.map (·.xs.size)).foldl max 0, view := some f.viewConfig,
    plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces }

theorem accessOf_traces (name : String) (f : Frame) (traces : Array Trace) : (accessOf name f traces).traces = traces := rfl

theorem accessOf_eq (name : String) (f : Frame) (traces : Array Trace) : accessOf name f traces =
    { name, series := traces.map fun _ => "line", points := (traces.map (·.xs.size)).foldl max 0, view := some f.viewConfig,
      plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces } := rfl

/-- The coloured series as the legend's, named `Series 1`, `Series 2` and so on, those `off` marks hidden. -/
def seriesTraces (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) : Array Trace :=
  (ss.zipIdx.map fun ((c, s), i) => traceOf s!"Series {i + 1}" c (off.getD i false) s).toArray

theorem seriesTraces_eq (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) : seriesTraces off ss =
    (ss.zipIdx.map fun ((c, s), i) => traceOf s!"Series {i + 1}" c (off.getD i false) s).toArray := rfl

theorem seriesTraces_size (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) : (seriesTraces off ss).size = ss.length := by
  simp [seriesTraces]

/-- The scene of a `width` by `height` chart in `f`: `chart` draws the data, given the width and height of text, and the axes' labels go over it. With `traces` it has a legend, and a cursor over the plot. -/
def frameScene (width height : Nat) (f : Frame) (chart : (String → Float × Float) → Scene.DisplayList)
    (name : String := "Chart") (traces : Array Trace := #[]) : IO Scene := do
  let measure ← measurer "12px sans-serif" (texts f)
  let labels := tickLabels (axes f measure)
  pure { commands := Gpu.frameBytes width height (chart measure) background, labels,
         access := if traces.isEmpty then {} else accessOf name f traces }

/-- Draw each chart `build` makes from the series its legend has hidden, and again when a click on a legend entry hides or shows one. -/
def registerLegend (build : String → Array Bool → IO Scene) : IO Unit := do
  let hidden ← IO.mkRef (({} : Std.HashMap String (Array Bool)))
  register "inkproof-chart" fun src => do build src ((← hidden.get).getD src #[])
  let toggled ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      let src ← el.callMethod "getAttribute" #[toJS "src"] String
      let detail ← event.get "detail" Value
      let series ← detail.get "series" Nat
      let hide ← detail.get "hidden" Bool
      let old := (← hidden.get).getD src #[]
      let off := (old ++ Array.replicate (series + 1 - old.size) false).setIfInBounds series hide
      hidden.modify (·.insert src off)
      setScene el (← build src off)
    return .undefined
  (← (← global).get "document").callMethod "addEventListener" #[toJS "inkproof-series", toJS toggled] Unit

/-- The scene of a chart of lines: its axes' labels over the data, and its layers as the legend's series unless they are in `off`. -/
def lineScene (c : Lines.Chart) (off : Array Bool := #[]) : IO Scene := do
  let measure ← measurer "12px sans-serif" c.labelTexts.toArray
  let sides := [Side.bottom, .left] ++ (c.right.map fun _ => Side.right).toList
  let labels := ((c.axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  pure { commands := Gpu.frameBytes c.width c.height ((c.hide off).display measure) background, labels,
         access := accessOf c.name c.frame (seriesTraces off (c.layers.map fun l => (l.color, l.data))) }

/-- The scene of a `width` by `height` chart on `bg`: `axes` lie on `sides` in order, their labels go over `chart`'s data, and `texts` are every label they may show. -/
def sidedScene (width height : Nat) (bg : Color) (texts : Array String) (sides : List Side)
    (axes : (String → Float × Float) → List AxisDrawing) (chart : (String → Float × Float) → Scene.DisplayList) : IO Scene := do
  let measure ← measurer "12px sans-serif" texts
  let labels := ((axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  pure { commands := Gpu.frameBytes width height (chart measure) bg, labels }

/-- The value written at the end of each labelled bar of `c`. -/
def barLabels (c : Bars.Chart) : Array Label :=
  c.bars.filterMap fun b => b.label.map fun v =>
    let r := b.rect
    let text := Inkproof.Web.showFloat (Rat.toFloat v)
    if c.horizontal then
      { text, x := Rat.toFloat (if b.positive then max r.x0 r.x1 + 3 else min r.x0 r.x1 - 3), y := Rat.toFloat ((r.y0 + r.y1) / 2),
        align := if b.positive then .start else .end, baseline := .middle, font := "10px sans-serif" }
    else
      { text, x := Rat.toFloat ((r.x0 + r.x1) / 2), y := Rat.toFloat (if b.positive then min r.y0 r.y1 - 2 else max r.y0 r.y1 + 2),
        align := .center, baseline := if b.positive then .bottom else .top, font := "10px sans-serif" }

/-- The chart with the series in `off` drawn without bars; the others keep their places. -/
def hideBars (c : Bars.Chart) (off : Array Bool) : Bars.Chart :=
  { c with series := c.series.zipIdx.map fun (s, i) =>
      if off.getD i false then { s with values := s.values.map fun _ => none } else s }

theorem hideBars_series (c : Bars.Chart) (off : Array Bool) : (hideBars c off).series =
    c.series.zipIdx.map fun (s, i) => if off.getD i false then { s with values := s.values.map fun _ => none } else s := rfl

/-- The legend's entries for the series of a bar chart, named `Series 1`, `Series 2` and so on, those `off` marked hidden; they carry no data, so the legend is a static one. -/
def barTraces (c : Bars.Chart) (off : Array Bool) : Array Trace :=
  c.series.zipIdx.map fun (s, i) =>
    { name := s!"Series {i + 1}", color := cssColor s.fill, hidden := off.getD i false, xs := #[], ys := #[] }

theorem barTraces_eq (c : Bars.Chart) (off : Array Bool) : barTraces c off =
    c.series.zipIdx.map fun (s, i) =>
      { name := s!"Series {i + 1}", color := cssColor s.fill, hidden := off.getD i false, xs := #[], ys := #[] } := rfl

/-- The legend's entries for the clouds of a scatter plot, named `Series 1`, `Series 2` and so on, those `off` marked hidden; they carry no data, so the legend is a static one. -/
def cloudTraces (cs : Array Scatter.Cloud) (off : Array Bool) : Array Trace :=
  cs.zipIdx.map fun (c, i) =>
    { name := s!"Series {i + 1}", color := cssColor c.color, hidden := off.getD i false, xs := #[], ys := #[] }

theorem cloudTraces_eq (cs : Array Scatter.Cloud) (off : Array Bool) : cloudTraces cs off =
    cs.zipIdx.map fun (c, i) =>
      { name := s!"Series {i + 1}", color := cssColor c.color, hidden := off.getD i false, xs := #[], ys := #[] } := rfl

/-- The scene of a bar chart: its axes and bars, with each bar's value written at its end. -/
def barScene (c : Bars.Chart) (off : Option (Array Bool) := none) : IO Scene := do
  let shown := off.elim c (hideBars c)
  let s ← sidedScene c.width c.height background c.texts c.sides c.axes shown.display
  pure { s with labels := s.labels ++ barLabels shown,
                access := off.elim {} fun off => { name := "Bars", traces := barTraces c off } }

/-- The frame of a pane for the cursor: x counts categories from 0, so category `i` is at `i + 1/2`, and y is the left axis. -/
def paneFrame (p : Pane.Pane) : Frame := ⟨p.plot.x0, p.plot.x1, p.plot.y0, p.plot.y1, (0, p.groups.size), p.left⟩

theorem paneFrame_eq (p : Pane.Pane) : paneFrame p = ⟨p.plot.x0, p.plot.x1, p.plot.y0, p.plot.y1, (0, p.groups.size), p.left⟩ := rfl

/-- The legend's group of values named `labels`, one row of `values` for each category of `p`, drawn in `color`; the group is the chart's marks, so it cannot be hidden. -/
def paneGroup (p : Pane.Pane) (name : String) (color : Color) (labels : Array String) (values : Array (Array Rat)) : ValueGroup :=
  { name, color := cssColor color, labels, xs := (Array.range p.groups.size).map fun i => (i.toFloat + 0.5),
    values := values.map fun row => row.map Rat.toFloat }

theorem paneGroup_values (p : Pane.Pane) (name : String) (color : Color) (labels : Array String) (values : Array (Array Rat)) :
    (paneGroup p name color labels values).values = values.map fun row => row.map Rat.toFloat := rfl

/-- The scene of a pane whose shapes are `shapes`; with `groups` it has a legend, and a cursor over the plot. -/
def paneScene (p : Pane.Pane) (shapes : Scene.DisplayList) (name : String := "Chart") (groups : Array ValueGroup := #[]) : IO Scene := do
  let s ← sidedScene p.width p.height background p.texts p.sides p.axes (p.display shapes)
  let f := paneFrame p
  pure { s with access := if groups.isEmpty then {} else
    { name, points := p.groups.size, view := some f.viewConfig, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), groups } }

/-- The scene of a timeline: its axes and bars, with each bar's state written on it. -/
def timelineScene (c : Timeline.Chart) : IO Scene := do
  let s ← sidedScene c.width c.height background c.labelTexts [.bottom, .left] c.axes c.display
  pure { s with labels := s.labels ++ c.texts.map fun (text, x, y) =>
    { text, x := Rat.toFloat x, y := Rat.toFloat y, align := if c.centred then .center else .start, baseline := .middle, font := "14px Arial" } }

end Inkproof.Demos.Browser
