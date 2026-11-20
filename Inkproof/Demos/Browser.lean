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

namespace Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Scene Inkproof.Axis

/-- The labels of a bottom axis followed by those of a left axis. -/
def tickLabels (axes : List AxisDrawing) : Array Label :=
  (axes.zip [Side.bottom, Side.left]).toArray.flatMap fun (a, side) => Label.ofDrawing side a

theorem tickLabels_eq (axes : List AxisDrawing) :
    tickLabels axes = (axes.zip [Side.bottom, Side.left]).toArray.flatMap fun (a, side) => Label.ofDrawing side a := rfl

/-- The scene of a `width` by `height` chart in `f`: `chart` draws the data, given the width and height of text, and the axes' labels go over it. -/
def frameScene (width height : Nat) (f : Frame) (chart : (String → Float × Float) → Scene.DisplayList) : IO Scene := do
  let measure ← measurer "12px sans-serif" (texts f)
  let labels := tickLabels (axes f measure)
  pure { commands := Gpu.frameBytes width height (chart measure) background, labels }

/-- The scene of a chart of lines: its axes' labels over the data. -/
def lineScene (c : Lines.Chart) : IO Scene := do
  let measure ← measurer "12px sans-serif" c.labelTexts.toArray
  let sides := [Side.bottom, .left] ++ (c.right.map fun _ => Side.right).toList
  let labels := ((c.axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  pure { commands := Gpu.frameBytes c.width c.height (c.display measure) background, labels }

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

/-- The scene of a bar chart: its axes and bars, with each bar's value written at its end. -/
def barScene (c : Bars.Chart) : IO Scene := do
  let s ← sidedScene c.width c.height background c.texts c.sides c.axes c.display
  pure { s with labels := s.labels ++ barLabels c }

/-- The scene of a pane whose shapes are `shapes`. -/
def paneScene (p : Pane.Pane) (shapes : Scene.DisplayList) : IO Scene :=
  sidedScene p.width p.height background p.texts p.sides p.axes (p.display shapes)

/-- The scene of a timeline: its axes and bars, with each bar's state written on it. -/
def timelineScene (c : Timeline.Chart) : IO Scene := do
  let s ← sidedScene c.width c.height background c.labelTexts [.bottom, .left] c.axes c.display
  pure { s with labels := s.labels ++ c.texts.map fun (text, x, y) =>
    { text, x := Rat.toFloat x, y := Rat.toFloat y, align := if c.centred then .center else .start, baseline := .middle, font := "14px Arial" } }

end Inkproof.Demos.Browser
