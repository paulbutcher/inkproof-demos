/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof

def percent (v : Int) : String := s!"{v / 100}.{if v % 100 < 10 then "0" else ""}{v % 100}"

def main : IO Unit :=
  register "inkproof-chart" fun _ => do
    let numbers := (List.range 12).map (fun (i : Nat) => toString (i * 10000)) ++ (List.range 11).map (fun (i : Nat) => toString (i * 10))
    let measure ← measurer "12px sans-serif" numbers.toArray
    let exts := ServerEvents.series.map fun f => ServerEvents.extents f
    let axes := ServerEvents.axes measure
    let ticks := Browser.tickLabels measure axes
    let css := ["#f00", "#008000", "#00f"]
    let notes := ((ServerEvents.names.zip ServerEvents.series).zip exts).zipIdx.toArray.map fun (((name, f), e), i) =>
      { text := s!"{name}: highest {percent (ServerEvents.highest f)} %, drawn {percent (ServerEvents.drawnHighest e)} %",
        x := 60 + 370 * i.toFloat, y := 24, font := "bold 13px sans-serif", color := css[i]?.getD "#000" : Label }
    pure { commands := Page.bytes 1200 640 (ServerEvents.chart exts measure), labels := ticks ++ notes }
