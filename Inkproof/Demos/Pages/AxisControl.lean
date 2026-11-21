/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.AxisControl

open Inkproof.Web.Host Inkproof.Demos Inkproof.Scene Inkproof

def run : IO Unit :=
  register "inkproof-chart" fun _ => do
    let measure ← measurer "12px sans-serif" (AxisControl.labelTexts ++ ["X Axis Label", "Y Axis Label"]).toArray
    let axes := AxisControl.axes measure
    let ticks := (axes.zip [Side.bottom, .right]).toArray.flatMap fun (a, side) => Label.ofDrawing side a
    let f := AxisControl.frame
    let (w, _) := measure "X Axis Label"
    let (h, _) := measure "Y Axis Label"
    let xTitle : Label := { text := "X Axis Label", x := Rat.toFloat ((f.left + f.right) / 2) - w / 2, y := Rat.toFloat f.bottom + 45 }
    let yTitle : Label := { text := "Y Axis Label", x := Rat.toFloat f.right + 50, y := Rat.toFloat ((f.top + f.bottom) / 2) - h / 2, rotation := 1.5707963267948966 }
    pure { commands := Gpu.frameBytes 1048 600 (AxisControl.chart measure) background, labels := ticks ++ #[xTitle, yTitle],
           access := Browser.accessOf "Axis Control" f (Browser.seriesTraces #[] [(AxisControl.red, AxisControl.series)]) }

end Page.AxisControl
