/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Axis
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Frame
import Inkproof.Demos.Page

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
  pure { commands := Page.bytes width height (chart measure), labels }

/-- The scene of a chart of lines: its axes' labels over the data. -/
def lineScene (c : Lines.Chart) : IO Scene := do
  let measure ← measurer "12px sans-serif" c.labelTexts.toArray
  let sides := [Side.bottom, .left] ++ (c.right.map fun _ => Side.right).toList
  let labels := ((c.axes measure).zip sides).toArray.flatMap fun (a, side) => Label.ofDrawing side a
  pure { commands := Page.bytes c.width c.height (c.display measure), labels }

end Inkproof.Demos.Browser
