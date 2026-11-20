/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Gpu.Frame
import Inkproof.Scene
import Inkproof.Viewport
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines

namespace Inkproof.Demos.Zoom

open Inkproof.Core Inkproof.Gpu Inkproof.Scene Inkproof.Scale Inkproof.Viewport Inkproof.Demos

/-- One line of a zooming chart. -/
structure Line where
  xs : Array Rat
  ys : Array Rat
  color : Color

/-- A chart of lines that the pointer zooms and pans. A chart that shows only part of its data, such as one fetched for a range, gives the extent of all of it as `bounds`. -/
structure Chart where
  width : Nat
  height : Nat
  lines : List Line
  bounds : Option ((Rat × Rat) × (Rat × Rat)) := none

/-- The two series of uPlot's wheel and touch zoom pages. -/
def basic : Chart :=
  let xs : Array Rat := #[1, 2, 3, 4, 5, 6, 7]
  ⟨600, 400, [⟨xs, #[40, 43, 60, 65, 71, 73, 80], ⟨255, 0, 0, 255⟩⟩, ⟨xs, #[18, 24, 37, 55, 55, 60, 63], ⟨0, 0, 255, 255⟩⟩], none⟩

/-- Thirty points of a fixed hash of the index in `-10..10`, drawn in purple, as the variations page does. -/
def variation : Chart :=
  let xs : Array Rat := (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)
  ⟨600, 400, [⟨xs, (Data.ints 7 30 0 20).map fun (v : Nat) => ((v : Int) - 10 : Int), ⟨128, 0, 128, 255⟩⟩], none⟩

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

/-- The lines in data coordinates, which a frame draws under any view without a new upload. -/
def Chart.data (c : Chart) : DisplayList :=
  c.lines.foldl (fun d l =>
    d ++ compileLine ⟨⟨1, l.color⟩, 1 / 2, false, none, .straight⟩ ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some)))) #[]

theorem Chart.data_eq (c : Chart) : c.data = c.lines.foldl (fun d l =>
    d ++ compileLine ⟨⟨1, l.color⟩, 1 / 2, false, none, .straight⟩ ⟨id, id⟩ (Segmented.single (Lines.series l.xs (l.ys.map some)))) #[] := rfl

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

/-- The commands of a frame of `c` under `v`, and the cache after it. Buffers hold the lines of every view, so a frame uploads only the axes, which change with the view; a cache that starts at another handle keeps charts that share a context apart. -/
def Chart.commands (c : Chart) (cache : Cache) (fresh : Bool) (v : Viewport.View Float) (measure : String → Float × Float) :
    Cache × List Cmd :=
  let f := c.viewFrame v
  let w := c.width
  let h := c.height
  let data := Gpu.View.mk f.xs.1 f.xs.2 f.ys.1 f.ys.2
  viewOverlayFrame (tessellateStroke ⟨0, 0⟩) cache fresh w h data (plot f) c.data (axisDisplay f measure) background

theorem Chart.commands_eq (c : Chart) (cache : Cache) (fresh : Bool) (v : Viewport.View Float) (measure : String → Float × Float) :
    c.commands cache fresh v measure =
      let f := c.viewFrame v
      viewOverlayFrame (tessellateStroke ⟨0, 0⟩) cache fresh c.width c.height (Gpu.View.mk f.xs.1 f.xs.2 f.ys.1 f.ys.2)
        (plot f) c.data (axisDisplay f measure) background := rfl

end Inkproof.Demos.Zoom
