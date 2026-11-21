/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame

namespace Inkproof.Demos.Lines

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- The points `(xs[i], ys[i])`, a value of `none` being missing. -/
def series (xs : Array Rat) (ys : Array (Option Rat)) : Series Rat Rat :=
  Series.ofUnsorted (xs.zip ys)

theorem series_eq (xs : Array Rat) (ys : Array (Option Rat)) : series xs ys = Series.ofUnsorted (xs.zip ys) := rfl

/-- Values given in units of `1 / scale`, as the numbers they stand for. -/
def scaled (scale : Nat) (vals : Array Int) : Array Rat := vals.map fun (v : Int) => (v : Rat) / scale

theorem scaled_eq (scale : Nat) (vals : Array Int) : scaled scale vals = vals.map fun (v : Int) => (v : Rat) / scale := rfl

/-- `ys` with the entries at `gaps` missing. -/
def withGaps (gaps : List Nat) (ys : Array Rat) : Array (Option Rat) :=
  ys.mapIdx fun i y => if gaps.contains i then none else some y

theorem withGaps_eq (gaps : List Nat) (ys : Array Rat) :
    withGaps gaps ys = ys.mapIdx fun i y => if gaps.contains i then none else some y := rfl

/-- A y axis: the range it shows, a unit written after each label, and whether its ticks have gridlines. -/
structure YAxis where
  range : Rat × Rat
  suffix : String := ""
  grid : Bool := true

/-- A colour that varies along an axis between stops placed at data values, ascending. -/
structure Gradient where
  axis : GradientAxis
  first : Rat × Color
  rest : List (Rat × Color)

/-- The stops in the order the plane meets them: y grows downwards, so a y gradient lists them from the highest value. -/
def Gradient.ordered (g : Gradient) : List (Rat × Color) :=
  match g.axis with
  | .x => g.first :: g.rest
  | .y => (g.first :: g.rest).reverse

theorem Gradient.ordered_eq (g : Gradient) : g.ordered =
    match g.axis with
    | .x => g.first :: g.rest
    | .y => (g.first :: g.rest).reverse := rfl

def Gradient.shading (g : Gradient) (p : Projection Rat Rat) : Shading :=
  match g.ordered, g.axis with
  | s :: r, .x => p.gradientX s r
  | s :: r, .y => p.gradientY s r
  | [], _ => .flat ⟨0, 0, 0, 0⟩

theorem Gradient.shading_eq (g : Gradient) (p : Projection Rat Rat) : g.shading p =
    match g.ordered, g.axis with
    | s :: r, .x => p.gradientX s r
    | s :: r, .y => p.gradientY s r
    | [], _ => .flat ⟨0, 0, 0, 0⟩ := rfl

/-- One drawn series. A gradient replaces the colour of the stroke or fill it names. -/
structure Layer where
  data : Series Rat Rat
  color : Color
  fill : Option Color := none
  halfWidth : Rat := 1 / 2
  dash : Option DashPattern := none
  onRight : Bool := false
  /-- Adjacent points further apart than this are not joined. -/
  maxStep : Option Rat := none
  join : Join := .straight
  strokeGradient : Option Gradient := none
  fillGradient : Option Gradient := none

/-- The filled space between two layers, where both have a value. -/
structure Band where
  lower : Nat
  upper : Nat
  color : Color

/-- A chart of series sharing an x axis (Unix times when `time`), with a left y axis and optionally a right one. -/
structure Chart where
  name : String
  width : Nat
  height : Nat
  xs : Rat × Rat
  time : Bool
  left : YAxis
  right : Option YAxis := none
  layers : List Layer
  bands : List Band := []

/-- Every value present in the layers. -/
def values (layers : List Layer) : List Rat := layers.flatMap fun l => l.data.values.toList.filterMap id

theorem values_eq (layers : List Layer) : values layers = layers.flatMap fun l => l.data.values.toList.filterMap id := rfl

/-- The y axis showing every value of the layers, as `autoRange` pads them. -/
def autoYAxis (layers : List Layer) (suffix : String := "") : YAxis :=
  match values layers with
  | [] => { range := (0, 1), suffix }
  | v :: vs => { range := autoRange (1 / 10) (vs.foldl min v) (vs.foldl max v), suffix }

theorem autoYAxis_eq (layers : List Layer) (suffix : String) : autoYAxis layers suffix =
    match values layers with
    | [] => { range := (0, 1), suffix }
    | v :: vs => { range := autoRange (1 / 10) (vs.foldl min v) (vs.foldl max v), suffix } := rfl

def Chart.frame (c : Chart) : Frame :=
  ⟨60, c.width - (if c.right.isSome then 80 else 20), 20, c.height - 40, c.xs, c.left.range⟩

theorem Chart.frame_eq (c : Chart) :
    c.frame = ⟨60, c.width - (if c.right.isSome then 80 else 20), 20, c.height - 40, c.xs, c.left.range⟩ := rfl

/-- Data to pixels along a y axis of `a`. -/
def Chart.yScale (c : Chart) (a : YAxis) : Linear Rat :=
  ⟨a.range.1, a.range.2, c.frame.bottom, c.frame.top⟩

theorem Chart.yScale_eq (c : Chart) (a : YAxis) : c.yScale a = ⟨a.range.1, a.range.2, c.frame.bottom, c.frame.top⟩ := rfl

def Chart.xScale (c : Chart) : Linear Rat := ⟨c.xs.1, c.xs.2, c.frame.left, c.frame.right⟩

theorem Chart.xScale_eq (c : Chart) : c.xScale = ⟨c.xs.1, c.xs.2, c.frame.left, c.frame.right⟩ := rfl

/-- Data to pixels for `layer`, along the axis it is drawn against. -/
def Chart.projection (c : Chart) (l : Layer) : Projection Rat Rat :=
  ⟨c.xScale.map, (c.yScale (if l.onRight then c.right.getD c.left else c.left)).map⟩

theorem Chart.projection_x (c : Chart) (l : Layer) (x : Rat) : (c.projection l).x x = c.xScale.map x := rfl

/-- The tick values and labels of a y axis. -/
def YAxis.ticks (a : YAxis) : List Float × List String :=
  let ts := linearTicks (Rat.toFloat a.range.1) (Rat.toFloat a.range.2) 10
  (ts, (tickLabels .en ts).map (· ++ a.suffix))

theorem YAxis.ticks_eq (a : YAxis) : a.ticks =
    (linearTicks (Rat.toFloat a.range.1) (Rat.toFloat a.range.2) 10,
     (tickLabels .en (linearTicks (Rat.toFloat a.range.1) (Rat.toFloat a.range.2) 10)).map (· ++ a.suffix)) := rfl

/-- About one tick every 120 pixels along a time axis. -/
def Chart.timeTarget (c : Chart) : Nat := c.width / 120

theorem Chart.timeTarget_eq (c : Chart) : c.timeTarget = c.width / 120 := rfl

/-- Every label an axis may show: the browser measures these before the axes choose among them. -/
def Chart.labelTexts (c : Chart) : List String :=
  (if c.time then (Axes.timeTicks (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2) c.timeTarget).2
   else Axes.linearLabels (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2)) ++
  c.left.ticks.2 ++ (c.right.map (·.ticks.2)).getD []

theorem Chart.labelTexts_eq (c : Chart) : c.labelTexts =
    (if c.time then (Axes.timeTicks (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2) c.timeTarget).2
     else Axes.linearLabels (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2)) ++
    c.left.ticks.2 ++ (c.right.map (·.ticks.2)).getD [] := rfl

def Chart.axes (c : Chart) (measure : String → Float × Float) : List AxisDrawing :=
  let f := c.frame
  let yAxis (side : Side) (a : YAxis) :=
    let (ts, ls) := a.ticks
    let scale : Linear Float := ⟨Rat.toFloat a.range.1, Rat.toFloat a.range.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩
    compilePixelAxis side (plot f) (if a.grid then Axes.style else { Axes.style with grid := none }) measure
      Axes.spec.labelGap (ts.map scale.map) ls
  [if c.time then f.timeAxis c.timeTarget measure else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
   yAxis .left c.left] ++ (c.right.map (yAxis .right)).toList

theorem Chart.axes_eq (c : Chart) (measure : String → Float × Float) : c.axes measure =
    let f := c.frame
    let yAxis (side : Side) (a : YAxis) :=
      let (ts, ls) := a.ticks
      let scale : Linear Float := ⟨Rat.toFloat a.range.1, Rat.toFloat a.range.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩
      compilePixelAxis side (plot f) (if a.grid then Axes.style else { Axes.style with grid := none }) measure
        Axes.spec.labelGap (ts.map scale.map) ls
    [if c.time then f.timeAxis c.timeTarget measure else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
     yAxis .left c.left] ++ (c.right.map (yAxis .right)).toList := rfl

/-- The layer's strokes, split where its `maxStep` says the data has a gap. -/
def Layer.segments (l : Layer) : Segmented Rat Rat :=
  match l.maxStep with
  | some d => Segmented.splitWhere l.data fun a b => decide (d < b - a)
  | none => Segmented.single l.data

theorem Layer.segments_eq (l : Layer) : l.segments =
    match l.maxStep with
    | some d => Segmented.splitWhere l.data fun a b => decide (d < b - a)
    | none => Segmented.single l.data := rfl

/-- The band between layers `b.lower` and `b.upper`: a column at each x where both have a value. -/
def Chart.bandDisplay (c : Chart) (b : Band) : DisplayList :=
  match c.layers[b.lower]?, c.layers[b.upper]? with
  | some lo, some hi =>
    let cols := (lo.data.values.zip hi.data.values).map fun (a, z) => do pure (← a, ← z)
    compileEnvelope ⟨0, b.color⟩ ⟨fun i => c.xScale.map (lo.data.xs.getD i 0), (c.yScale c.left).map⟩ cols
  | _, _ => #[]

theorem Chart.bandDisplay_eq (c : Chart) (b : Band) : c.bandDisplay b =
    match c.layers[b.lower]?, c.layers[b.upper]? with
    | some lo, some hi =>
      let cols := (lo.data.values.zip hi.data.values).map fun (a, z) => do pure (← a, ← z)
      compileEnvelope ⟨0, b.color⟩ ⟨fun i => c.xScale.map (lo.data.xs.getD i 0), (c.yScale c.left).map⟩ cols
    | _, _ => #[] := rfl

/-- What the layer's stroke is painted with. -/
def Layer.strokeShading (l : Layer) (p : Projection Rat Rat) : Shading :=
  match l.strokeGradient with
  | some g => g.shading p
  | none => .flat l.color

theorem Layer.strokeShading_eq (l : Layer) (p : Projection Rat Rat) : l.strokeShading p =
    match l.strokeGradient with
    | some g => g.shading p
    | none => .flat l.color := rfl

/-- What the layer's fill is painted with, if it has one. -/
def Layer.fillShading (l : Layer) (p : Projection Rat Rat) : Option Shading :=
  match l.fillGradient with
  | some g => some (g.shading p)
  | none => l.fill.map .flat

theorem Layer.fillShading_eq (l : Layer) (p : Projection Rat Rat) : l.fillShading p =
    match l.fillGradient with
    | some g => some (g.shading p)
    | none => l.fill.map .flat := rfl

/-- The layer filled down to the bottom of its axis, then stroked. -/
def Chart.layerDisplay (c : Chart) (l : Layer) : DisplayList :=
  (match l.fillShading (c.projection l) with
    | some f => compileArea ⟨0, f⟩ (if l.onRight then (c.right.getD c.left).range.1 else c.left.range.1) (c.projection l) l.segments l.join
    | none => #[]) ++
  compileLine ⟨⟨1, l.strokeShading (c.projection l)⟩, l.halfWidth, false, l.dash, l.join⟩ (c.projection l) l.segments

theorem Chart.layerDisplay_eq (c : Chart) (l : Layer) : c.layerDisplay l =
    (match l.fillShading (c.projection l) with
      | some f => compileArea ⟨0, f⟩ (if l.onRight then (c.right.getD c.left).range.1 else c.left.range.1) (c.projection l) l.segments l.join
      | none => #[]) ++
    compileLine ⟨⟨1, l.strokeShading (c.projection l)⟩, l.halfWidth, false, l.dash, l.join⟩ (c.projection l) l.segments := rfl

/-- The chart without the data of the layers `off` marks, so that they draw nothing and leave the others where they were. -/
def Chart.hide (c : Chart) (off : Array Bool) : Chart :=
  { c with layers := c.layers.zipIdx.map fun (l, i) => if off.getD i false then { l with data := {} } else l }

theorem Chart.hide_layers (c : Chart) (off : Array Bool) : (c.hide off).layers =
    c.layers.zipIdx.map fun (l, i) => if off.getD i false then { l with data := {} } else l := rfl

/-- The axes, then the bands and each layer in turn. -/
def Chart.display (c : Chart) (measure : String → Float × Float) : DisplayList :=
  (c.axes measure).foldl (· ++ ·.display) #[] ++ c.bands.foldl (· ++ c.bandDisplay ·) #[] ++
    c.layers.foldl (· ++ c.layerDisplay ·) #[]

theorem Chart.display_eq (c : Chart) (measure : String → Float × Float) : c.display measure =
    (c.axes measure).foldl (· ++ ·.display) #[] ++ c.bands.foldl (· ++ c.bandDisplay ·) #[] ++
      c.layers.foldl (· ++ c.layerDisplay ·) #[] := rfl

end Inkproof.Demos.Lines
