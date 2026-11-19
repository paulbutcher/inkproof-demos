/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos

def main : IO Unit :=
  register "inkproof-chart" fun _ => do
    let f := AreaFill.frame
    let numbers := (List.range 30).map (fun i => toString i) ++ (List.range 25).map (fun (i : Nat) => toString ((i : Int) - 12))
    let measure ← measurer "12px sans-serif" numbers.toArray
    let axes := axes f measure
    let labels := Browser.tickLabels axes
    pure { commands := Page.bytes 1200 600 (AreaFill.chart f measure), labels }
