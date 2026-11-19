/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure

open Inkproof.Web.Host Inkproof.Demos Inkproof

/-- Tick labels centred under or right-aligned beside their ticks; the element's text layer has no alignment or rotation of its own. -/
def labelsOf (measure : String → Float × Float) (left : Bool) (axis : Scene.AxisDrawing) : Array Label :=
  axis.labels.toArray.map fun l =>
    let (w, h) := measure l.text
    let x := AreaFill.flt l.anchor.x
    let y := AreaFill.flt l.anchor.y
    if left then { text := l.text, x := x - w, y := y + h / 4 } else { text := l.text, x := x - w / 2, y := y + h }

def main : IO Unit :=
  register "inkproof-chart" fun _ => do
    let f := AreaFill.frame
    let numbers := (List.range 30).map (fun i => toString i) ++ (List.range 25).map (fun (i : Nat) => toString ((i : Int) - 12))
    let measure ← measurer "12px sans-serif" numbers.toArray
    let axes := AreaFill.axes f measure
    let labels := (axes.zip [false, true]).toArray.flatMap fun (a, left) => labelsOf measure left a
    pure { commands := Page.bytes 1200 600 (AreaFill.chart f measure), labels }
