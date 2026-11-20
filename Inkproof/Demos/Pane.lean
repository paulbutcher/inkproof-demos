/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Float
import Inkproof.Scale
import Inkproof.Scene
import Inkproof.Demos.Axes

namespace Inkproof.Demos.Pane

open Inkproof.Axis Inkproof.Core Inkproof.Scale Inkproof.Scene Inkproof.Demos

/-- A plot with named categories along the bottom and a value axis on the left, and on the right where it has a second. The shapes of the page are placed in pixels, a category at a time. -/
structure Pane where
  width : Nat
  height : Nat
  groups : Array String
  left : Rat × Rat
  right : Option (Rat × Rat) := none
  /-- The room under the plot for the category labels. -/
  below : Nat := 40
  /-- About how many category labels to show. -/
  target : Nat := 48

def Pane.plot (p : Pane) : Rect := ⟨60, 18, p.width - (if p.right.isSome then 60 else 10), p.height - p.below⟩

theorem Pane.plot_eq (p : Pane) :
    p.plot = ⟨60, 18, p.width - (if p.right.isSome then 60 else 10), p.height - p.below⟩ := rfl

def Pane.categories (p : Pane) : Categorical String Rat := ⟨p.groups, p.plot.x0, p.plot.x1⟩

theorem Pane.categories_eq (p : Pane) : p.categories = ⟨p.groups, p.plot.x0, p.plot.x1⟩ := rfl

/-- The pixel column through the middle of category `i`. -/
def Pane.centre (p : Pane) (i : Nat) : Rat := p.categories.bandStart i + p.categories.bandwidth / 2

theorem Pane.centre_eq (p : Pane) (i : Nat) : p.centre i = p.categories.bandStart i + p.categories.bandwidth / 2 := rfl

/-- The pixel row of value `v` on the scale `range`. -/
def Pane.row (p : Pane) (range : Rat × Rat) (v : Rat) : Rat := (Linear.mk range.1 range.2 p.plot.y1 p.plot.y0).map v

theorem Pane.row_eq (p : Pane) (range : Rat × Rat) (v : Rat) :
    p.row range v = (Linear.mk range.1 range.2 p.plot.y1 p.plot.y0).map v := rfl

/-- The category axis along the bottom, the left axis and the right one if there is one. -/
def Pane.axes (p : Pane) (measure : String → Float × Float) : List AxisDrawing :=
  let r := p.plot
  let value (range : Rat × Rat) : Linear Float :=
    ⟨Rat.toFloat range.1, Rat.toFloat range.2, Rat.toFloat r.y1, Rat.toFloat r.y0⟩
  let categories : Categorical String Float := ⟨p.groups, Rat.toFloat r.x0, Rat.toFloat r.x1⟩
  [compileCategoricalAxis .bottom r categories id p.target Axes.spec.labelGap measure { Axes.style with grid := none },
   compileLinearAxis .left r (value p.left) Axes.spec measure Axes.style] ++
  (p.right.map fun range =>
    compileLinearAxis .right r (value range) Axes.spec measure { Axes.style with grid := none }).toList

theorem Pane.axes_eq (p : Pane) (measure : String → Float × Float) : p.axes measure =
    let r := p.plot
    let value (range : Rat × Rat) : Linear Float :=
      ⟨Rat.toFloat range.1, Rat.toFloat range.2, Rat.toFloat r.y1, Rat.toFloat r.y0⟩
    let categories : Categorical String Float := ⟨p.groups, Rat.toFloat r.x0, Rat.toFloat r.x1⟩
    [compileCategoricalAxis .bottom r categories id p.target Axes.spec.labelGap measure { Axes.style with grid := none },
     compileLinearAxis .left r (value p.left) Axes.spec measure Axes.style] ++
    (p.right.map fun range =>
      compileLinearAxis .right r (value range) Axes.spec measure { Axes.style with grid := none }).toList := rfl

def Pane.sides (p : Pane) : List Side := [.bottom, .left] ++ (p.right.map fun _ => Side.right).toList

theorem Pane.sides_eq (p : Pane) : p.sides = [.bottom, .left] ++ (p.right.map fun _ => Side.right).toList := rfl

/-- Every label the axes may show, for the host to measure. -/
def Pane.texts (p : Pane) : Array String :=
  p.groups ++ (Axes.linearLabels (Rat.toFloat p.left.1) (Rat.toFloat p.left.2)).toArray ++
    ((p.right.map fun r => Axes.linearLabels (Rat.toFloat r.1) (Rat.toFloat r.2)).getD []).toArray

theorem Pane.texts_eq (p : Pane) : p.texts =
    p.groups ++ (Axes.linearLabels (Rat.toFloat p.left.1) (Rat.toFloat p.left.2)).toArray ++
      ((p.right.map fun r => Axes.linearLabels (Rat.toFloat r.1) (Rat.toFloat r.2)).getD []).toArray := rfl

/-- The axes, then `shapes` cut off at the plot's edge. -/
def Pane.display (p : Pane) (shapes : DisplayList) (measure : String → Float × Float) : DisplayList :=
  (p.axes measure).foldl (· ++ ·.display) #[] ++ DisplayList.clip p.plot shapes

theorem Pane.display_eq (p : Pane) (shapes : DisplayList) (measure : String → Float × Float) : p.display shapes measure =
    (p.axes measure).foldl (· ++ ·.display) #[] ++ DisplayList.clip p.plot shapes := rfl

/-- A line from `(x0, y0)` to `(x1, y1)` in pixels, `width` thick. -/
def line (color : Color) (width : Rat) (dash : Option DashPattern) (x0 y0 x1 y1 : Rat) : DisplayList :=
  compileLine ⟨⟨2, color⟩, width / 2, false, dash, .straight⟩ ⟨id, id⟩
    (Segmented.single (Series.ofUnsorted #[(x0, some y0), (x1, some y1)] : Series Rat Rat))

theorem line_eq (color : Color) (width : Rat) (dash : Option DashPattern) (x0 y0 x1 y1 : Rat) : line color width dash x0 y0 x1 y1 =
    compileLine ⟨⟨2, color⟩, width / 2, false, dash, .straight⟩ ⟨id, id⟩
      (Segmented.single (Series.ofUnsorted #[(x0, some y0), (x1, some y1)] : Series Rat Rat)) := rfl

/-- A rectangle filled with `fill` and outlined by four edges `w` thick inside it, drawn in `layer`. -/
def outlined (layer : Nat) (stroke fill : Color) (w : Rat) (r : Rect) : DisplayList :=
  let v := min w ((r.x1 - r.x0) / 2)
  #[⟨layer, fill, .rect r⟩, ⟨layer + 1, stroke, .rect ⟨r.x0, r.y0, r.x1, r.y0 + w⟩⟩, ⟨layer + 1, stroke, .rect ⟨r.x0, r.y1 - w, r.x1, r.y1⟩⟩,
    ⟨layer + 1, stroke, .rect ⟨r.x0, r.y0, r.x0 + v, r.y1⟩⟩, ⟨layer + 1, stroke, .rect ⟨r.x1 - v, r.y0, r.x1, r.y1⟩⟩]

theorem outlined_eq (layer : Nat) (stroke fill : Color) (w : Rat) (r : Rect) : outlined layer stroke fill w r =
    let v := min w ((r.x1 - r.x0) / 2)
    #[⟨layer, fill, .rect r⟩, ⟨layer + 1, stroke, .rect ⟨r.x0, r.y0, r.x1, r.y0 + w⟩⟩, ⟨layer + 1, stroke, .rect ⟨r.x0, r.y1 - w, r.x1, r.y1⟩⟩,
      ⟨layer + 1, stroke, .rect ⟨r.x0, r.y0, r.x0 + v, r.y1⟩⟩, ⟨layer + 1, stroke, .rect ⟨r.x1 - v, r.y0, r.x1, r.y1⟩⟩] := rfl

end Inkproof.Demos.Pane
