/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.AxisControl

open Inkproof.Web.Host Inkproof.Demos Inkproof.Scene Inkproof

/-- The colour uPlot gives the right axis's labels and title; its ticks and gridlines stay faint. -/
def axisRed : String := "red"

def run : IO Unit :=
  Browser.registerPixels fun _ px => do
    let measure ← measurer Browser.font (AxisControl.labelTexts).toArray
    let axes := AxisControl.axes measure px.theme
    let ticks := (axes.zip [Side.bottom, .right]).toArray.flatMap fun (a, side) =>
      (Label.ofDrawing side a).map fun l => if side == .right then { l with color := axisRed } else l
    let f := AxisControl.frame
    let r := plot f
    let titles ← (axes.zip [(Side.bottom, "X Axis Label"), (.right, "Y Axis Label")]).toArray.mapM fun (a, side, text) => do
      let t ← axisTitleMeasured side r (Axes.styled px.theme) a text
      pure (if side == .right then { t.label with color := axisRed } else t.label)
    pure { commands := px.frameBytes (AxisControl.chart measure px.theme) px.background, labels := ticks ++ titles,
           access := Browser.accessOf "Axis Control" f (Browser.seriesTraces #[] [(AxisControl.red, AxisControl.series)] ["sin(x)"]) }

end Page.AxisControl
