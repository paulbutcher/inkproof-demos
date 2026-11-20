/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof

def main : IO Unit :=
  register "inkproof-chart" fun _ => do
    let seed ← Browser.seed
    let width ← Browser.windowWidth
    let f := AreaFill.frame width
    let numbers := (List.range 30).map (fun i => toString i) ++ (List.range 25).map (fun (i : Nat) => toString ((i : Int) - 12))
    let measure ← measurer "12px sans-serif" numbers.toArray
    let labels := Browser.tickLabels (axes f measure)
    pure { commands := Gpu.frameBytes width (AreaFill.height width) (AreaFill.chart seed f measure) background, labels }
