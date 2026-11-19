/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure

namespace Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Scene

/-- Tick labels centred under or right-aligned beside their ticks; the element's text layer has no alignment or rotation of its own. -/
def labelsOf (measure : String → Float × Float) (left : Bool) (axis : AxisDrawing) : Array Label :=
  axis.labels.toArray.map fun l =>
    let (w, h) := measure l.text
    let x := flt l.anchor.x
    let y := flt l.anchor.y
    if left then { text := l.text, x := x - w, y := y + h / 4 } else { text := l.text, x := x - w / 2, y := y + h }

theorem labelsOf_eq (measure : String → Float × Float) (left : Bool) (axis : AxisDrawing) :
    labelsOf measure left axis = axis.labels.toArray.map fun l =>
      let (w, h) := measure l.text
      if left then { text := l.text, x := flt l.anchor.x - w, y := flt l.anchor.y + h / 4 }
      else { text := l.text, x := flt l.anchor.x - w / 2, y := flt l.anchor.y + h } := rfl

end Inkproof.Demos.Browser
