/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene.Scale
import Inkproof.Demos
import Inkproof.Web.Host.Axis
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Frame
import Inkproof.Demos.Bars
import Inkproof.Web.Access
import Inkproof.Web.Host.Console
import Inkproof.Web.Host.SceneCache
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
  { name, series := traces.map fun _ => "line", points := (traces.map (·.xs.size)).foldl max 0, view := some f.viewConfig, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces }

theorem accessOf_traces (name : String) (f : Frame) (traces : Array Trace) : (accessOf name f traces).traces = traces := rfl

theorem accessOf_eq (name : String) (f : Frame) (traces : Array Trace) : accessOf name f traces =
    { name, series := traces.map fun _ => "line", points := (traces.map (·.xs.size)).foldl max 0, view := some f.viewConfig,
      plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces } := rfl

/-- The coloured series as the legend's, those `off` marks hidden, each named as `names` says and `Value` where it doesn't, as uPlot names a series without a label. -/
def seriesTraces (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) (names : List String := []) : Array Trace :=
  (ss.zipIdx.map fun ((c, s), i) => traceOf (names.getD i "Value") c (off.getD i false) s).toArray

theorem seriesTraces_eq (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) (names : List String) : seriesTraces off ss names =
    (ss.zipIdx.map fun ((c, s), i) => traceOf (names.getD i "Value") c (off.getD i false) s).toArray := rfl

theorem seriesTraces_size (off : Array Bool) (ss : List (Color × Core.Series Rat Rat)) (names : List String) : (seriesTraces off ss names).size = ss.length := by
  simp [seriesTraces]

/-- The sizes of a chart's canvas: in CSS pixels, and in the device pixels of its backing store. -/
structure Pixels where
  css : Nat × Nat
  backing : Nat × Nat

/-- How many device pixels make a CSS pixel across the canvas. -/
def Pixels.ratio (p : Pixels) : Rat := if p.css.1 = 0 then 1 else (p.backing.1 : Rat) / p.css.1

theorem Pixels.ratio_eq (p : Pixels) : p.ratio = if p.css.1 = 0 then 1 else (p.backing.1 : Rat) / p.css.1 := rfl

/-- The wire bytes of a frame of `list`, laid out in CSS pixels, for the canvas's backing store: the list is scaled by the device pixel ratio so its clips, strokes and markers match the canvas. -/
def Pixels.frameBytes (p : Pixels) (list : Scene.DisplayList) (bg : Color) : ByteArray :=
  Gpu.strokeFrameBytes p.backing.1 p.backing.2 (list.scale p.ratio) bg

theorem Pixels.frameBytes_eq (p : Pixels) (list : Scene.DisplayList) (bg : Color) :
    p.frameBytes list bg = Gpu.strokeFrameBytes p.backing.1 p.backing.2 (list.scale p.ratio) bg := rfl

/-- The legend's group of values named `labels`, one row of `values` at each of `xs` in the data's own units, drawn in `color`; the group is the chart's marks, so it cannot be hidden. -/
def valueGroup (name : String) (color : Color) (labels : Array String) (xs : Array Rat) (values : Array (Array Rat)) : ValueGroup :=
  { name, color := cssColor color, labels, xs := xs.map Rat.toFloat, values := values.map fun row => row.map Rat.toFloat }

theorem valueGroup_values (name : String) (color : Color) (labels : Array String) (xs : Array Rat) (values : Array (Array Rat)) :
    (valueGroup name color labels xs values).values = values.map fun row => row.map Rat.toFloat := rfl

/-- The font the axes' labels are set in, for measuring them. -/
def font : String := Host.textFont Axes.text

/-- The access of a chart in `f` whose legend reads `groups`, and which has a cursor over the plot. -/
def groupsAccess (name : String) (f : Frame) (groups : Array ValueGroup) : Access :=
  { name, points := (groups.getD 0 { name, color := "", labels := #[], xs := #[] }).xs.size, view := some f.viewConfig,
    plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), groups }

theorem groupsAccess_eq (name : String) (f : Frame) (groups : Array ValueGroup) : groupsAccess name f groups =
    { name, points := (groups.getD 0 { name, color := "", labels := #[], xs := #[] }).xs.size, view := some f.viewConfig,
      plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), groups } := rfl

/-- The scene of a chart in `f`: `chart` draws the data, given the width and height of text, and the axes' labels go over it. With `traces` or `groups` it has a legend, and a cursor over the plot. -/
def frameScene (px : Pixels) (f : Frame) (chart : (String → Float × Float) → Scene.DisplayList)
    (name : String := "Chart") (traces : Array Trace := #[]) (groups : Array ValueGroup := #[]) : IO Scene := do
  let measure ← measurer font (texts f)
  let labels := tickLabels (axes f measure)
  pure { commands := px.frameBytes (chart measure) background, labels,
         access := if !groups.isEmpty then groupsAccess name f groups else if traces.isEmpty then {} else accessOf name f traces }

/-- Define the chart element: it draws the scene `build` makes of its `src` for its canvas's sizes. -/
def registerPixels (build : String → Pixels → IO Scene) (buttons : Bool := false) : IO Unit :=
  Host.registerPixels "inkproof-chart" (fun src css backing => build src ⟨css, backing⟩) buttons

/-- A part of a chart that the legend can hide: drawn unless `hidden` says so for the legend's hidden series. -/
structure Part where
  display : Scene.DisplayList
  hidden : Array Bool → Bool

/-- The parts `displays`, each hidden with the legend's series of its index. -/
def Part.indexed (displays : Array Scene.DisplayList) : Array Part :=
  displays.zipIdx.map fun (display, i) => ⟨display, (·.getD i false)⟩

theorem Part.indexed_eq (displays : Array Scene.DisplayList) :
    Part.indexed displays = displays.zipIdx.map fun (display, i) => ⟨display, (·.getD i false)⟩ := rfl

/-- A chart as parts the legend shows or hides: what is always drawn, the parts that may be hidden, the axes' labels, and what the legend reads for the hidden series. -/
structure Drawing where
  base : Scene.DisplayList
  parts : Array Part
  labels : Array Label
  access : Array Bool → Access

/-- A chart's buffers on the GPU and the draws recorded for the layers in them, kept across frames. -/
structure Retention where
  cache : SceneCache

def Retention.new : IO Retention := do pure { cache := ← SceneCache.new }

/-- Forget the buffers, as when the chart's data changed. -/
def Retention.invalidate (r : Retention) : IO Unit := r.cache.invalidate

/-- Build a frame with `f`, given what the chart holds, and keep what `f` leaves. -/
def Retention.build {α : Type} (r : Retention) (f : Gpu.Retained → Bool → IO (Gpu.Retained × α)) : IO α :=
  r.cache.buildRetained f

/-- A drawing's display lists cut into the pieces of each paint layer and tessellated once, in the pixels of `p`: piece `j` of a layer is the base's (`j = 0`) or part `j - 1`'s commands on it. Drawing the pieces layer by layer paints what the concatenated lists paint. -/
def Pixels.retain (p : Pixels) (d : Drawing) : Array (Array Gpu.Layer) :=
  let lists := #[d.base] ++ d.parts.map (·.display)
  let scaled := lists.map (·.scale p.ratio)
  let numbers := (scaled.flatMap fun l => l.map (·.layer)).qsort (· < ·) |>.toList.eraseDups
  numbers.toArray.map fun n => scaled.map fun l => Gpu.Layer.stroke (l.filter (·.layer == n))

theorem Pixels.retain_eq (p : Pixels) (d : Drawing) : p.retain d =
    let scaled := (#[d.base] ++ d.parts.map (·.display)).map (·.scale p.ratio)
    let numbers := (scaled.flatMap fun l => l.map (·.layer)).qsort (· < ·) |>.toList.eraseDups
    numbers.toArray.map fun n => scaled.map fun l => Gpu.Layer.stroke (l.filter (·.layer == n)) := rfl

/-- The scene of `d` with its hidden parts left out, from pieces `retained` by `p.retain d` and the buffers `cache` keeps on the GPU: no piece is tessellated or uploaded again. -/
def Pixels.drawRetained (p : Pixels) (cache : Retention) (d : Drawing) (retained : Array (Array Gpu.Layer)) (off : Array Bool) : IO Scene := do
  let shown (j : Nat) := j == 0 || !(d.parts[j - 1]?.elim false (·.hidden off))
  let pick (keep : Bool) := retained.toList.flatMap fun pieces => (pieces.toList.zipIdx.filter fun (_, j) => shown j == keep).map (·.1)
  let bytes ← cache.build fun old first => pure (Gpu.strokeLayersBytes old first p.backing.1 p.backing.2 (pick true) (pick false) background)
  pure { commands := bytes, labels := d.labels, access := d.access off }

/-- The scene of a chart drawn once for each size of its canvas, and again for each set of hidden series without making or tessellating anything again. -/
def Pixels.drawing (p : Pixels) (cache : Retention) (d : Drawing) : IO (Array Bool → IO Scene) := do
  let retained := p.retain d
  pure (p.drawRetained cache d retained)

/-- Define the chart element, and draw each chart `build` makes of its `src` for its canvas's size and the series its legend has hidden. A click on a legend entry hides or shows a series by calling what `build` returned again, and only a change of size calls `build` again. `build` is given the cache of the chart's buffers on the GPU. -/
def registerRetained (build : String → Pixels → Retention → IO (Array Bool → IO Scene)) : IO Unit := do
  let hidden ← IO.mkRef (({} : Std.HashMap String (Array Bool)))
  let draws ← IO.mkRef (({} : Std.HashMap String (Array Bool → IO Scene)))
  let caches ← IO.mkRef (({} : Std.HashMap String Retention))
  registerPixels fun src px => do
    let cache ← match (← caches.get).get? src with
      | some c => pure c
      | none => do let c ← Retention.new; caches.modify (·.insert src c); pure c
    let draw ← build src px cache
    draws.modify (·.insert src draw)
    draw ((← hidden.get).getD src #[])
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
      if let some draw := (← draws.get).get? src then setScene el (← draw off)
    return .undefined
  (← (← global).get "document").callMethod "addEventListener" #[toJS "inkproof-series", toJS toggled] Unit

/-- Draw each chart `build` makes from the series its legend has hidden, and again when a click on a legend entry hides or shows one or the canvas changes size; `build` runs again for every click. -/
def registerLegend (build : String → Pixels → Array Bool → IO Scene) : IO Unit :=
  registerRetained fun src px _ => pure (build src px)

/-- The drawing of a chart of lines: its axes, then its bands, each shown while the layers it lies between are, and each layer; the legend's series are the layers. -/
def lineDrawing (c : Lines.Chart) : IO Drawing := do
  let measure ← measurer font c.labelTexts.toArray
  let sides := [Side.bottom, .left] ++ (c.right.map fun _ => Side.right).toList
  let labels := ((c.axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  let off (i : Nat) (h : Array Bool) := h.getD i false
  pure { base := (c.axes measure).foldl (· ++ ·.display) #[], labels
         parts := (c.bands.map fun b => ⟨c.bandDisplay b, fun h => off b.lower h || off b.upper h⟩).toArray ++
           (c.layers.zipIdx.map fun (l, i) => ⟨c.layerDisplay l, off i⟩).toArray
         access := fun h => accessOf c.name c.frame (seriesTraces h (c.layers.map fun l => (l.color, l.data)) (c.layers.map (·.label))) }

/-- Draw the chart of `charts` that each element's `src` names, its legend hiding its layers. -/
def registerLines (charts : List Lines.Chart) : IO Unit :=
  registerRetained fun src px cache => do
    let some c := charts.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    px.drawing cache (← lineDrawing c)

/-- The scene of a chart on `bg`: `axes` lie on `sides` in order, their labels go over `chart`'s data, and `texts` are every label they may show. -/
def sidedScene (px : Pixels) (bg : Color) (texts : Array String) (sides : List Side)
    (axes : (String → Float × Float) → List AxisDrawing) (chart : (String → Float × Float) → Scene.DisplayList) : IO Scene := do
  let measure ← measurer font texts
  let labels := ((axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  pure { commands := px.frameBytes (chart measure) bg, labels }

/-- The value written at the end of each labelled bar of `c`. -/
def barLabels (c : Bars.Chart) (style : TextStyle := {}) : Array Label :=
  c.bars.filterMap fun b => b.label.map fun v =>
    let r := b.rect
    let text := (Axes.numbers.format (Rat.toFloat v)).getD ""
    if c.horizontal then
      { text, x := Rat.toFloat (if b.positive then max r.x0 r.x1 + 3 else min r.x0 r.x1 - 3), y := Rat.toFloat ((r.y0 + r.y1) / 2),
        align := if b.positive then .start else .end, baseline := .middle, font := Host.textFont style, color := Host.colorCss style.color }
    else
      { text, x := Rat.toFloat ((r.x0 + r.x1) / 2), y := Rat.toFloat (if b.positive then min r.y0 r.y1 - 2 else max r.y0 r.y1 + 2),
        align := .center, baseline := if b.positive then .bottom else .top, font := Host.textFont style, color := Host.colorCss style.color }

theorem barLabels_text (c : Bars.Chart) (style : TextStyle) : (barLabels c style).map (·.text) =
    c.bars.filterMap fun b => b.label.map fun v => (Axes.numbers.format (Rat.toFloat v)).getD "" := by
  unfold barLabels
  simp only [Array.map_filterMap, Option.map_map, Function.comp_def]
  congr 1
  funext b
  cases b.label <;> simp <;> split <;> rfl

/-- The chart with the series in `off` drawn without bars, and the lines after them in `off` without strokes; the others keep their places. -/
def hideBars (c : Bars.Chart) (off : Array Bool) : Bars.Chart :=
  { c with
    series := c.series.zipIdx.map fun (s, i) =>
      if off.getD i false then { s with values := s.values.map fun _ => none } else s
    lines := (c.lines.zipIdx.filter fun (_, i) => !off.getD (c.series.size + i) false).map (·.1) }

theorem hideBars_series (c : Bars.Chart) (off : Array Bool) : (hideBars c off).series =
    c.series.zipIdx.map fun (s, i) => if off.getD i false then { s with values := s.values.map fun _ => none } else s := rfl

theorem hideBars_lines (c : Bars.Chart) (off : Array Bool) : (hideBars c off).lines =
    (c.lines.zipIdx.filter fun (_, i) => !off.getD (c.series.size + i) false).map (·.1) := rfl

/-- The legend's entries for the bar series of a chart and then its lines, each under its own name, those `off` marked hidden; they carry no data, so the legend is a static one. -/
def barTraces (c : Bars.Chart) (off : Array Bool) : Array Trace :=
  c.series.zipIdx.map (fun (s, i) =>
    { name := s.name, color := cssColor s.fill, hidden := off.getD i false, xs := #[], ys := #[] : Trace }) ++
  c.lines.zipIdx.map fun (l, i) =>
    { name := l.name, color := cssColor l.color, hidden := off.getD (c.series.size + i) false, xs := #[], ys := #[] }

theorem barTraces_eq (c : Bars.Chart) (off : Array Bool) : barTraces c off =
    c.series.zipIdx.map (fun (s, i) =>
      { name := s.name, color := cssColor s.fill, hidden := off.getD i false, xs := #[], ys := #[] : Trace }) ++
    c.lines.zipIdx.map fun (l, i) =>
      { name := l.name, color := cssColor l.color, hidden := off.getD (c.series.size + i) false, xs := #[], ys := #[] } := rfl

/-- The legend's entries for the clouds of a scatter plot, each under its own name, those `off` marked hidden; they carry no data, so the legend is a static one. -/
def cloudTraces (cs : Array Scatter.Cloud) (off : Array Bool) : Array Trace :=
  cs.zipIdx.map fun (c, i) =>
    { name := c.name, color := cssColor c.color, hidden := off.getD i false, xs := #[], ys := #[] }

theorem cloudTraces_eq (cs : Array Scatter.Cloud) (off : Array Bool) : cloudTraces cs off =
    cs.zipIdx.map fun (c, i) =>
      { name := c.name, color := cssColor c.color, hidden := off.getD i false, xs := #[], ys := #[] } := rfl

/-- The drawing of a chart in `f`: `axesDisplay` is drawn always and each of `parts` unless the legend hides the series of its index; the legend is `traces`. -/
def frameDrawing (f : Frame) (axesDisplay : (String → Float × Float) → Scene.DisplayList) (parts : Array Scene.DisplayList)
    (name : String) (traces : Array Bool → Array Trace) : IO Drawing := do
  let measure ← measurer font (texts f)
  pure { base := axesDisplay measure, labels := tickLabels (axes f measure)
         parts := Part.indexed parts
         access := fun off => { name, traces := traces off } }

/-- The scene of a bar chart: its axes and bars, with each bar's value written at its end. -/
def barScene (px : Pixels) (c : Bars.Chart) (off : Option (Array Bool) := none) : IO Scene := do
  let shown := off.elim c (hideBars c)
  let s ← sidedScene px background c.texts c.sides c.axes shown.display
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
def paneScene (px : Pixels) (p : Pane.Pane) (shapes : Scene.DisplayList) (name : String := "Chart") (groups : Array ValueGroup := #[]) : IO Scene := do
  let s ← sidedScene px background p.texts p.sides p.axes (p.display shapes)
  let f := paneFrame p
  pure { s with access := if groups.isEmpty then {} else
    { name, points := p.groups.size, view := some f.viewConfig, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), groups } }

/-- The places along x where row `r` has a state to read, with the state: each bar's two ends, and the middle of each gap between bars, which has none. -/
def rowStates (r : Timeline.Row) : Array (Rat × Option String) :=
  r.spans.zipIdx.flatMap fun (s, i) =>
    let gap : Array (Rat × Option String) := match r.spans[i + 1]? with
      | some n => if s.stop < n.start then #[((s.stop + n.start) / 2, none)] else #[]
      | none => #[]
    #[(s.start, some s.text), (s.stop, some s.text)] ++ gap

theorem rowStates_eq (r : Timeline.Row) : rowStates r =
    r.spans.zipIdx.flatMap fun (s, i) =>
      let gap : Array (Rat × Option String) := match r.spans[i + 1]? with
        | some n => if s.stop < n.start then #[((s.stop + n.start) / 2, none)] else #[]
        | none => #[]
      #[(s.start, some s.text), (s.stop, some s.text)] ++ gap := rfl

/-- The legend's group for row `r`: the row's state at the x nearest the cursor. -/
def rowGroup (r : Timeline.Row) : ValueGroup :=
  let states := rowStates r
  { name := r.name, color := cssColor (r.spans[0]?.elim ⟨0, 0, 0, 255⟩ (·.stroke)), labels := #["State"],
    xs := states.map fun (x, _) => x.toFloat, words := states.map fun (_, t) => #[t] }

theorem rowGroup_words (r : Timeline.Row) : (rowGroup r).words = (rowStates r).map fun (_, t) => #[t] := rfl

/-- The scene of a timeline: its axes and bars, with each bar's state written on it, and a legend that reads each row's state at the cursor. -/
def timelineScene (px : Pixels) (c : Timeline.Chart) : IO Scene := do
  let s ← sidedScene px background c.labelTexts [.bottom, .left] c.axes c.display
  let f := c.frame
  let labels := c.texts.map fun (text, x, y) =>
    { text, x := Rat.toFloat x, y := Rat.toFloat y, align := if c.centred then .center else .start, baseline := .middle, font := Host.textFont { family := "Arial", size := 14 } }
  let access : Access := { name := c.name, points := c.rows.size, view := some f.viewConfig, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), groups := c.rows.map rowGroup }
  pure { s with labels := s.labels ++ labels, access }

end Inkproof.Demos.Browser
