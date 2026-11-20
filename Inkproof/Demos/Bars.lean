/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scale
import Inkproof.Scene
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame

namespace Inkproof.Demos.Bars

open Inkproof.Axis Inkproof.Core Inkproof.Scale Inkproof.Scene Inkproof.Demos

/-- One series of bars: a value for each group, missing where `none`, drawn against the value range `range`. -/
structure Series where
  fill : Color
  values : Array (Option Rat)
  range : Rat × Rat
  /-- The fill and outline of each group's bar where they differ from group to group. -/
  groupColors : Array (Color × Color) := #[]

/-- A line through the groups' centres at the values `values` of the scale `range`. -/
structure Line where
  color : Color
  values : Array Rat
  range : Rat × Rat

/-- A chart of bars over named groups. Bars of one group stand side by side, or on top of each other when `stacked`; categories run along the horizontal axis, or down the vertical one when `horizontal`. -/
structure Chart where
  width : Nat
  height : Nat
  groups : Array String
  series : Array Series
  lines : Array Line := #[]
  stacked : Bool := false
  horizontal : Bool := false
  /-- The range of the value axis, on the first series' scale. -/
  axis : Rat × Rat

/-- The rectangle the bars and their axes share. -/
def Chart.plot (c : Chart) : Rect :=
  if c.horizontal then ⟨150, 30, c.width - 30, c.height - 10⟩ else ⟨60, 18, c.width - 10, c.height - 40⟩

theorem Chart.plot_eq (c : Chart) :
    c.plot = if c.horizontal then ⟨150, 30, c.width - 30, c.height - 10⟩ else ⟨60, 18, c.width - 10, c.height - 40⟩ := rfl

/-- Where value `v` of a series with `range` lies along the value direction of the plot, in pixels. -/
def Chart.along (c : Chart) (range : Rat × Rat) (v : Rat) : Rat :=
  let p := c.plot
  if c.horizontal then (Linear.mk range.1 range.2 p.x0 p.x1).map v else (Linear.mk range.1 range.2 p.y1 p.y0).map v

theorem Chart.along_eq (c : Chart) (range : Rat × Rat) (v : Rat) :
    c.along range v = if c.horizontal then (Linear.mk range.1 range.2 c.plot.x0 c.plot.x1).map v
      else (Linear.mk range.1 range.2 c.plot.y1 c.plot.y0).map v := rfl

/-- The categories laid out across the plot in the category direction. -/
def Chart.categories (c : Chart) : Categorical String Rat :=
  let p := c.plot
  if c.horizontal then ⟨c.groups, p.y0, p.y1⟩ else ⟨c.groups, p.x0, p.x1⟩

theorem Chart.categories_eq (c : Chart) : c.categories =
    if c.horizontal then ⟨c.groups, c.plot.y0, c.plot.y1⟩ else ⟨c.groups, c.plot.x0, c.plot.x1⟩ := by
  unfold Chart.categories
  cases c.horizontal <;> rfl

/-- The group's band across the category direction, as the start and the length: its 90% in the middle holds the bars. -/
def Chart.block (c : Chart) (g : Nat) : Rat × Rat :=
  (c.categories.bandStart g + c.categories.bandwidth / 20, c.categories.bandwidth * 9 / 10)

theorem Chart.block_eq (c : Chart) (g : Nat) :
    c.block g = (c.categories.bandStart g + c.categories.bandwidth / 20, c.categories.bandwidth * 9 / 10) := rfl

/-- A bar: its rectangle, its colour with an outline if it has one, and the value written at its end, if any. -/
structure Bar where
  rect : Rect
  fill : Color
  label : Option Rat
  positive : Bool
  outline : Option Color := none
  outlineWidth : Rat := 1

/-- The colour a bar of `s` in group `g` is filled with, and its outline where the series gives one. -/
def Series.colorsOf (s : Series) (g : Nat) : Color × Option Color :=
  match s.groupColors[g]? with
  | some (f, o) => (f, some o)
  | none => (s.fill, none)

theorem Series.colorsOf_eq (s : Series) (g : Nat) :
    s.colorsOf g = match s.groupColors[g]? with | some (f, o) => (f, some o) | none => (s.fill, none) := rfl

/-- The extent along the category direction of bar `s` of `n` side by side in a block at `start` of length `len`. -/
def slot (start len : Rat) (n s : Nat) : Rat × Rat :=
  (start + len * s / n, start + len * (s + 1) / n)

theorem slot_eq (start len : Rat) (n s : Nat) : slot start len n s = (start + len * s / n, start + len * (s + 1) / n) := rfl

/-- The rectangle covering `a` to `b` along the value direction and `u` to `v` along the category direction. -/
def Chart.rect (c : Chart) (a b u v : Rat) : Rect :=
  if c.horizontal then ⟨a, u, b, v⟩ else ⟨u, a, v, b⟩

theorem Chart.rect_eq (c : Chart) (a b u v : Rat) :
    c.rect a b u v = if c.horizontal then ⟨a, u, b, v⟩ else ⟨u, a, v, b⟩ := rfl

/-- The bars of the chart, group by group. Where stacked, the values pile up from zero and only the top bar is labelled, with the total; a missing value has no bar. -/
def Chart.bars (c : Chart) : Array Bar :=
  (List.range c.groups.size).toArray.flatMap fun g =>
    let (start, len) := c.block g
    let indexed := c.series.toList.zipIdx.filter fun (s, _) => (s.values.getD g none).isSome
    if c.stacked then
      let last := indexed.getLast?.map (·.2)
      let total := indexed.foldl (fun acc (s, _) => acc + (s.values.getD g none).getD 0) 0
      (indexed.foldl (fun (acc : Rat × Array Bar) (s, i) =>
        let v := (s.values.getD g none).getD 0
        let top := acc.1 + v
        (top, acc.2.push ⟨c.rect (c.along s.range acc.1) (c.along s.range top) start (start + len), s.fill,
          if last == some i then some total else none, 0 ≤ v, none, 1⟩)) (0, #[])).2
    else
      indexed.toArray.map fun (s, i) =>
        let v := (s.values.getD g none).getD 0
        let (u, w) := slot start len c.series.size i
        let (f, o) := s.colorsOf g
        ⟨c.rect (c.along s.range 0) (c.along s.range v) u w, f, some v, 0 ≤ v, o, 1⟩

theorem Chart.bars_eq (c : Chart) : c.bars =
  (List.range c.groups.size).toArray.flatMap fun g =>
    let (start, len) := c.block g
    let indexed := c.series.toList.zipIdx.filter fun (s, _) => (s.values.getD g none).isSome
    if c.stacked then
      let last := indexed.getLast?.map (·.2)
      let total := indexed.foldl (fun acc (s, _) => acc + (s.values.getD g none).getD 0) 0
      (indexed.foldl (fun (acc : Rat × Array Bar) (s, i) =>
        let v := (s.values.getD g none).getD 0
        let top := acc.1 + v
        (top, acc.2.push ⟨c.rect (c.along s.range acc.1) (c.along s.range top) start (start + len), s.fill,
          if last == some i then some total else none, 0 ≤ v, none, 1⟩)) (0, #[])).2
    else
      indexed.toArray.map fun (s, i) =>
        let v := (s.values.getD g none).getD 0
        let (u, w) := slot start len c.series.size i
        let (f, o) := s.colorsOf g
        ⟨c.rect (c.along s.range 0) (c.along s.range v) u w, f, some v, 0 ≤ v, o, 1⟩ := rfl

/-- The axes: categories along one side and values along another. -/
def Chart.axes (c : Chart) (measure : String → Float × Float) : List AxisDrawing :=
  let p := c.plot
  let categories : Categorical String Float :=
    ⟨c.groups, Rat.toFloat c.categories.rangeStart, Rat.toFloat c.categories.rangeEnd⟩
  let scale : Linear Float :=
    if c.horizontal then ⟨Rat.toFloat c.axis.1, Rat.toFloat c.axis.2, Rat.toFloat p.x0, Rat.toFloat p.x1⟩
    else ⟨Rat.toFloat c.axis.1, Rat.toFloat c.axis.2, Rat.toFloat p.y1, Rat.toFloat p.y0⟩
  [compileCategoricalAxis (if c.horizontal then .left else .bottom) p categories id c.groups.size Axes.spec.labelGap measure
      { Axes.style with grid := none },
   compileLinearAxis (if c.horizontal then .top else .left) p scale Axes.spec measure Axes.style]

theorem Chart.axes_eq (c : Chart) (measure : String → Float × Float) : c.axes measure =
  let p := c.plot
  let categories : Categorical String Float :=
    ⟨c.groups, Rat.toFloat c.categories.rangeStart, Rat.toFloat c.categories.rangeEnd⟩
  let scale : Linear Float :=
    if c.horizontal then ⟨Rat.toFloat c.axis.1, Rat.toFloat c.axis.2, Rat.toFloat p.x0, Rat.toFloat p.x1⟩
    else ⟨Rat.toFloat c.axis.1, Rat.toFloat c.axis.2, Rat.toFloat p.y1, Rat.toFloat p.y0⟩
  [compileCategoricalAxis (if c.horizontal then .left else .bottom) p categories id c.groups.size Axes.spec.labelGap measure
      { Axes.style with grid := none },
   compileLinearAxis (if c.horizontal then .top else .left) p scale Axes.spec measure Axes.style] := rfl

/-- The sides the axes of `c` lie on, in order. -/
def Chart.sides (c : Chart) : List Side :=
  if c.horizontal then [.left, .top] else [.bottom, .left]

theorem Chart.sides_eq (c : Chart) : c.sides = if c.horizontal then [.left, .top] else [.bottom, .left] := rfl

/-- Every label the axes may show, for the host to measure. -/
def Chart.texts (c : Chart) : Array String :=
  c.groups ++ (Axes.linearLabels (Rat.toFloat c.axis.1) (Rat.toFloat c.axis.2)).toArray

theorem Chart.texts_eq (c : Chart) :
    c.texts = c.groups ++ (Axes.linearLabels (Rat.toFloat c.axis.1) (Rat.toFloat c.axis.2)).toArray := rfl

/-- A rectangle drawn as a one pixel outline round a filled inside. -/
def Bar.commands (b : Bar) : DisplayList :=
  match b.outline with
  | none => #[⟨1, b.fill, .rect b.rect⟩]
  | some o =>
    let r := b.rect
    let (x0, x1, y0, y1) := (min r.x0 r.x1, max r.x0 r.x1, min r.y0 r.y1, max r.y0 r.y1)
    #[⟨1, o, .rect ⟨x0, y0, x1, y1⟩⟩, ⟨1, b.fill, .rect ⟨x0 + b.outlineWidth, y0 + b.outlineWidth, x1 - b.outlineWidth, y1 - b.outlineWidth⟩⟩]

theorem Bar.commands_eq (b : Bar) : b.commands =
    match b.outline with
    | none => #[⟨1, b.fill, .rect b.rect⟩]
    | some o =>
      let r := b.rect
      let (x0, x1, y0, y1) := (min r.x0 r.x1, max r.x0 r.x1, min r.y0 r.y1, max r.y0 r.y1)
      #[⟨1, o, .rect ⟨x0, y0, x1, y1⟩⟩, ⟨1, b.fill, .rect ⟨x0 + b.outlineWidth, y0 + b.outlineWidth, x1 - b.outlineWidth, y1 - b.outlineWidth⟩⟩] := rfl

/-- The strokes of the lines, through the centre of each group. A projection cannot swap the axes, so a horizontal chart draws none. -/
def Chart.lineDisplay (c : Chart) : DisplayList :=
  if c.horizontal then #[] else
  c.lines.flatMap fun l =>
    let pts := (l.values.toList.zipIdx.map fun (v, g) =>
      let (s, len) := c.block g
      (s + len / 2, some v)).toArray
    let proj : Projection Rat Rat := ⟨fun x => x, c.along l.range⟩
    compileLine ⟨⟨2, l.color⟩, 1, false, none, .straight⟩ proj (Segmented.single (Series.ofUnsorted pts))

theorem Chart.lineDisplay_eq (c : Chart) : c.lineDisplay =
  if c.horizontal then #[] else
  c.lines.flatMap fun l =>
    let pts := (l.values.toList.zipIdx.map fun (v, g) =>
      let (s, len) := c.block g
      (s + len / 2, some v)).toArray
    let proj : Projection Rat Rat := ⟨fun x => x, c.along l.range⟩
    compileLine ⟨⟨2, l.color⟩, 1, false, none, .straight⟩ proj (Segmented.single (Series.ofUnsorted pts)) := rfl

/-- The axes, then the bars and the lines, cut off at the plot's edge. -/
def Chart.display (c : Chart) (measure : String → Float × Float) : DisplayList :=
  (c.axes measure).foldl (· ++ ·.display) #[] ++
    DisplayList.clip c.plot (c.bars.flatMap (·.commands) ++ c.lineDisplay)

theorem Chart.display_eq (c : Chart) (measure : String → Float × Float) : c.display measure =
    (c.axes measure).foldl (· ++ ·.display) #[] ++
      DisplayList.clip c.plot (c.bars.flatMap (·.commands) ++ c.lineDisplay) := rfl

end Inkproof.Demos.Bars
