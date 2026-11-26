/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser

namespace Page.ServerEvents

open Inkproof.Web.Host Inkproof.Demos Inkproof

def percent (v : Int) : String := s!"{v / 100}.{if v % 100 < 10 then "0" else ""}{v % 100}"

def run : IO Unit :=
  Browser.registerPixels fun _ px => do
    let measure ← measurer Browser.font ServerEvents.labelTexts
    let exts := ServerEvents.series.map fun f => ServerEvents.extents f
    let axes := ServerEvents.axes measure px.theme
    let ticks := Browser.sidedLabels axes
    let css := ["#f00", "#008000", "#00f"]
    let notes := ((ServerEvents.names.zip ServerEvents.series).zip exts).zipIdx.toArray.map fun (((name, f), e), i) =>
      { text := s!"{name}: highest {percent (ServerEvents.highest f)} %, drawn {percent (ServerEvents.drawnHighest e)} %",
        x := 60 + 370 * i.toFloat, y := 24, font := "bold 13px sans-serif", color := css[i]?.getD "#000" : Label }
    pure { commands := px.frameBytes (ServerEvents.chart exts measure px.theme) px.background, labels := ticks ++ notes }

end Page.ServerEvents
