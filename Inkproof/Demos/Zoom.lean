/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Gpu.Frame
import Inkproof.Gpu.Retained
import Inkproof.Scene
import Inkproof.Scene.Scale
import Inkproof.Viewport
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines
import Inkproof.Demos.Pane

namespace Inkproof.Demos.Zoom

open Inkproof.Core Inkproof.Gpu Inkproof.Scene Inkproof.Scale Inkproof.Viewport Inkproof.Demos Inkproof.Demos.Pane

/-- One line of a zooming chart, filled down to the bottom of the chart where it has a `fill`. -/
structure Line where
  xs : Array Rat
  ys : Array Rat
  color : Color
  fill : Option Color

/-- The line drawn at opacity `a`, its fill included. -/
def Line.dim (a : Rat) (l : Line) : Line :=
  { l with color := l.color.scaleAlpha a, fill := l.fill.map (·.scaleAlpha a) }

theorem Line.dim_eq (a : Rat) (l : Line) : l.dim a = { l with color := l.color.scaleAlpha a, fill := l.fill.map (·.scaleAlpha a) } := rfl

/-- A note on the x axis: a line at `start`, or a band from `start` to `stop`, drawn dashed over the data with its label in a box on the top or the bottom edge of the plot. -/
structure Mark where
  start : Rat
  stop : Rat
  label : String
  stroke : Color
  fill : Color
  atTop : Bool
  /-- What the note says when the pointer is over its label. -/
  description : String := ""

/-- A chart of lines that the pointer zooms and pans. A chart that shows only part of its data, such as one fetched for a range, gives the extent of all of it as `bounds`. -/
structure Chart where
  width : Nat
  height : Nat
  lines : List Line
  bounds : Option ((Rat × Rat) × (Rat × Rat))
  marks : List Mark
  unit : String := ""

/-- The chart with line `i` drawn at opacity `alphas[i]`; a line past the end of `alphas` is opaque. -/
def Chart.dimmed (c : Chart) (alphas : Array Float) : Chart :=
  { c with lines := c.lines.zipIdx.map fun (l, i) => l.dim ((Inkproof.Float.Float.toRat (alphas.getD i 1)).getD 1) }

theorem Chart.dimmed_lines (c : Chart) (alphas : Array Float) : (c.dimmed alphas).lines = c.lines.zipIdx.map fun (l, i) => l.dim ((Inkproof.Float.Float.toRat (alphas.getD i 1)).getD 1) := rfl

/-- The names uPlot's wheel and touch zoom pages give their series; the other pages leave theirs unnamed. -/
def legendNames (page : String) : List String :=
  if page == "zoom-wheel" || page == "zoom-touch" then ["One", "Two"] else []

theorem legendNames_eq (page : String) :
    legendNames page = if page == "zoom-wheel" || page == "zoom-touch" then ["One", "Two"] else [] := rfl

/-- The two series of uPlot's wheel and touch zoom pages. -/
def basic : Chart :=
  let xs : Array Rat := #[1, 2, 3, 4, 5, 6, 7]
  ⟨600, 400, [⟨xs, #[40, 43, 60, 65, 71, 73, 80], ⟨255, 0, 0, 255⟩, none⟩, ⟨xs, #[18, 24, 37, 55, 55, 60, 63], ⟨0, 0, 255, 255⟩, none⟩], none, [], ""⟩

/-- Thirty points of a fixed hash of the index in `-10..10`, drawn in purple, as the variations page does. -/
def variation : Chart :=
  let xs : Array Rat := (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)
  ⟨600, 400, [⟨xs, (Data.ints 7 30 0 20).map fun (v : Nat) => ((v : Int) - 10 : Int), ⟨128, 0, 128, 255⟩, none⟩], none, [], ""⟩

/-- The extent of every x value of the chart, and of every y value padded as an automatic axis would. -/
def Chart.ranges (c : Chart) : (Rat × Rat) × (Rat × Rat) :=
  c.bounds.getD <|
  let xs := c.lines.flatMap (·.xs.toList)
  let ys := c.lines.flatMap (·.ys.toList)
  match xs, ys with
  | x :: xs, y :: ys => ((xs.foldl min x, xs.foldl max x), autoRange (1 / 10) (ys.foldl min y) (ys.foldl max y))
  | _, _ => ((0, 1), (0, 1))

theorem Chart.ranges_eq (c : Chart) : c.ranges = c.bounds.getD
    (match c.lines.flatMap (·.xs.toList), c.lines.flatMap (·.ys.toList) with
    | x :: xs, y :: ys => ((xs.foldl min x, xs.foldl max x), autoRange (1 / 10) (ys.foldl min y) (ys.foldl max y))
    | _, _ => ((0, 1), (0, 1))) := rfl

def Chart.frame (c : Chart) : Frame := Frame.sized c.width c.height c.ranges.1 c.ranges.2

theorem Chart.frame_eq (c : Chart) : c.frame = Frame.sized c.width c.height c.ranges.1 c.ranges.2 := rfl

/-- No zoom out past the data, none in past a thousandth of its range. -/
def Chart.config (c : Chart) : ViewConfig Float :=
  let f := c.frame
  let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
    let span := Rat.toFloat (r.2 - r.1)
    ⟨Rat.toFloat length, span / 1000, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
  ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩

theorem Chart.config_eq (c : Chart) : c.config =
    let f := c.frame
    let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
      let span := Rat.toFloat (r.2 - r.1)
      ⟨Rat.toFloat length, span / 1000, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
    ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩ := rfl

/-- The rectangle of each mark that spans a range, over the whole height of the chart, drawn first because a pixel takes the colour of the last command to cover it. -/
def Chart.markData (c : Chart) : DisplayList :=
  (c.marks.filter (fun m => m.start < m.stop)).toArray.map (fun m => (⟨0, m.fill, .rect ⟨m.start, c.ranges.2.1, m.stop, c.ranges.2.2⟩⟩ : Command))

theorem Chart.markData_eq (c : Chart) : c.markData =
    (c.marks.filter (fun m => m.start < m.stop)).toArray.map (fun m => (⟨0, m.fill, .rect ⟨m.start, c.ranges.2.1, m.stop, c.ranges.2.2⟩⟩ : Command)) := rfl

/-- A line in data coordinates, which a frame draws under any view without a new upload, over the area it fills down to the least y of the chart. -/
def Chart.lineData (c : Chart) (l : Line) : DisplayList :=
  (l.fill.map fun f => compileArea ⟨0, f⟩ c.ranges.2.1 ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some)))).getD #[] ++
    compileLine ⟨⟨1, l.color⟩, Axes.strokeHalfWidth, false, none, .straight⟩ ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some)))

theorem Chart.lineData_eq (c : Chart) (l : Line) : c.lineData l =
    (l.fill.map fun f => compileArea ⟨0, f⟩ c.ranges.2.1 ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some)))).getD #[] ++
      compileLine ⟨⟨1, l.color⟩, Axes.strokeHalfWidth, false, none, .straight⟩ ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some))) := rfl

/-- The marks' rectangles, then each line, as the pieces a legend shows or hides: the first is always drawn, and piece `i + 1` is line `i`. -/
def Chart.pieces (c : Chart) : Array DisplayList := #[c.markData] ++ c.lines.toArray.map c.lineData

theorem Chart.pieces_eq (c : Chart) : c.pieces = #[c.markData] ++ c.lines.toArray.map c.lineData := rfl

/-- The pixel columns of the mark's start and stop in the frame `f`. -/
def Mark.columns (f : Frame) (m : Mark) : Rat × Rat :=
  let scale : Linear Rat := ⟨f.xs.1, f.xs.2, f.left, f.right⟩
  (scale.map m.start, scale.map m.stop)

theorem Mark.columns_eq (f : Frame) (m : Mark) : Mark.columns f m =
    (Linear.mk f.xs.1 f.xs.2 f.left f.right |>.map m.start, Linear.mk f.xs.1 f.xs.2 f.left f.right |>.map m.stop) := rfl

/-- Whether any of the mark lies within the x range of `f`. -/
def Mark.shown (f : Frame) (m : Mark) : Bool := m.start ≤ f.xs.2 && f.xs.1 ≤ m.stop

theorem Mark.shown_eq (f : Frame) (m : Mark) : Mark.shown f m = (m.start ≤ f.xs.2 && f.xs.1 ≤ m.stop) := rfl

/-- The box round the mark's label, at its left edge on the top or bottom of the plot; none where the measure is not a finite size. -/
def Mark.box (f : Frame) (measure : String → Float × Float) (m : Mark) : Option Rect :=
  let (w, h) := measure m.label
  match Inkproof.Float.Float.toRat w, Inkproof.Float.Float.toRat h with
  | some w, some h =>
    let (w, h) := (w + 10, h + 6)
    let x := (Mark.columns f m).1
    some (if m.atTop then ⟨x, f.top, x + w, f.top + h⟩ else ⟨x, f.bottom - h, x + w, f.bottom⟩)
  | _, _ => none

theorem Mark.box_eq (f : Frame) (measure : String → Float × Float) (m : Mark) : Mark.box f measure m =
    let (w, h) := measure m.label
    match Inkproof.Float.Float.toRat w, Inkproof.Float.Float.toRat h with
    | some w, some h =>
      let (w, h) := (w + 10, h + 6)
      let x := (Mark.columns f m).1
      some (if m.atTop then ⟨x, f.top, x + w, f.top + h⟩ else ⟨x, f.bottom - h, x + w, f.bottom⟩)
    | _, _ => none := rfl

/-- The mark's dashed edges and the box of its label; nothing where it lies outside the range, and no box where the label cannot be measured. -/
def Mark.commands (f : Frame) (measure : String → Float × Float) (m : Mark) : DisplayList :=
  let (a, b) := Mark.columns f m
  if !Mark.shown f m then #[] else
  DisplayList.clip (plot f)
    ((if m.start < m.stop then line m.stroke 2 (some ⟨5, 5⟩) b f.top b f.bottom else #[]) ++
      line m.stroke 2 (some ⟨5, 5⟩) a f.top a f.bottom ++
      ((Mark.box f measure m).map fun r => #[⟨3, m.fill, .rect r⟩] ++ DisplayList.outline r 2 .inside m.stroke 4).getD #[])

theorem Mark.commands_eq (f : Frame) (measure : String → Float × Float) (m : Mark) : Mark.commands f measure m =
    let (a, b) := Mark.columns f m
    if !Mark.shown f m then #[] else
    DisplayList.clip (plot f)
      ((if m.start < m.stop then line m.stroke 2 (some ⟨5, 5⟩) b f.top b f.bottom else #[]) ++
        line m.stroke 2 (some ⟨5, 5⟩) a f.top a f.bottom ++
        ((Mark.box f measure m).map fun r => #[⟨3, m.fill, .rect r⟩] ++ DisplayList.outline r 2 .inside m.stroke 4).getD #[]) := rfl

/-- The text of each mark in view, with the top left of where it is written: inside its box, which is where the mark begins. -/
def Chart.markTexts (c : Chart) (f : Frame) (measure : String → Float × Float) : List (String × Rat × Rat) :=
  (c.marks.filter fun m => Mark.shown f m && f.left ≤ (Mark.columns f m).1 && (Mark.columns f m).1 ≤ f.right).filterMap fun m =>
    (Mark.box f measure m).map fun b => (m.label, b.x0 + 5, b.y0 + 3)

theorem Chart.markTexts_eq (c : Chart) (f : Frame) (measure : String → Float × Float) : c.markTexts f measure =
    (c.marks.filter fun m => Mark.shown f m && f.left ≤ (Mark.columns f m).1 && (Mark.columns f m).1 ≤ f.right).filterMap fun m =>
      (Mark.box f measure m).map fun b => (m.label, b.x0 + 5, b.y0 + 3) := rfl

/-- The frame showing `v`: the axes follow the visible ranges. -/
def Chart.viewFrame (c : Chart) (v : Viewport.View Float) : Frame :=
  let f := c.frame
  let range (s : Interval Float) (d : Rat × Rat) : Rat × Rat :=
    ((Inkproof.Float.Float.toRat s.start).getD d.1, (Inkproof.Float.Float.toRat (s.start + s.span)).getD d.2)
  { f with xs := range v.x f.xs, ys := range v.y f.ys }

theorem Chart.viewFrame_eq (c : Chart) (v : Viewport.View Float) : c.viewFrame v =
    let f := c.frame
    let range (s : Interval Float) (d : Rat × Rat) : Rat × Rat :=
      ((Inkproof.Float.Float.toRat s.start).getD d.1, (Inkproof.Float.Float.toRat (s.start + s.span)).getD d.2)
    { f with xs := range v.x f.xs, ys := range v.y f.ys } := rfl

/-- The pieces of `c` tessellated once, with their sizes scaled by `k`, for a target where a CSS pixel is `k` device pixels. -/
def Chart.retain (c : Chart) (k : Rat) : Array Gpu.Layer :=
  c.pieces.map fun d => Gpu.Layer.stroke (DisplayList.scaleSizes k d)

theorem Chart.retain_eq (c : Chart) (k : Rat) : c.retain k = c.pieces.map fun d => Gpu.Layer.stroke (DisplayList.scaleSizes k d) := rfl

/-- The encoded commands of a frame of `c` under `v`, and what is retained after it, for a target of `size` device pixels where a CSS pixel is `k` of them, from `layers` retained by `c.retain k`: the lines whose index is in `off` are left out but their buffers stay resident, so a frame uploads only the axes, which change with the view, and a line shown again uploads nothing. A cache that starts at another handle keeps charts that share a context apart, and a layer drawn before replays its recorded draws. -/
def Chart.commands (c : Chart) (cache : Retained) (fresh : Bool) (v : Viewport.View Float) (measure : String → Float × Float)
    (size : Nat × Nat) (k : Rat) (layers : Array Gpu.Layer) (off : Array Bool) (theme : Option Theme := none) : Retained × ByteArray :=
  let f := { c.viewFrame v with theme }
  let data := Gpu.View.mk f.xs.1 f.xs.2 f.ys.1 f.ys.2
  let hidden (j : Nat) := j != 0 && off.getD (j - 1) false
  let pick (keep : Bool) := (layers.toList.zipIdx.filter fun (_, j) => hidden j != keep).map (·.1)
  viewLayersBytes (tessellateStroke ⟨0, 0⟩) cache fresh size.1 size.2 data ((plot f).scale k) (pick true) (pick false)
    (((axisDisplayWith c.unit f measure) ++ c.marks.foldl (· ++ Mark.commands f measure ·) #[]).scale k) f.background

theorem Chart.commands_eq (c : Chart) (cache : Retained) (fresh : Bool) (v : Viewport.View Float) (measure : String → Float × Float)
    (size : Nat × Nat) (k : Rat) (layers : Array Gpu.Layer) (off : Array Bool) (theme : Option Theme) :
    c.commands cache fresh v measure size k layers off theme =
      let f := { c.viewFrame v with theme }
      let hidden (j : Nat) := j != 0 && off.getD (j - 1) false
      let pick (keep : Bool) := (layers.toList.zipIdx.filter fun (_, j) => hidden j != keep).map (·.1)
      viewLayersBytes (tessellateStroke ⟨0, 0⟩) cache fresh size.1 size.2 (Gpu.View.mk f.xs.1 f.xs.2 f.ys.1 f.ys.2)
        ((plot f).scale k) (pick true) (pick false)
        (((axisDisplayWith c.unit f measure) ++ c.marks.foldl (· ++ Mark.commands f measure ·) #[]).scale k) f.background := rfl

end Inkproof.Demos.Zoom
