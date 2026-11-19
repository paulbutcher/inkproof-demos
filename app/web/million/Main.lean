/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof

def main : IO Unit :=
  register "inkproof-chart" fun _ => do
    let numbers := (List.range 12).map (fun (i : Nat) => toString (i * 100000)) ++ (List.range 15).map (fun (i : Nat) => toString ((i : Int) * 100 - 300))
    let measure ← measurer "12px sans-serif" numbers.toArray
    let exts := Million.columnExtents Million.pyramid
    let shown := Million.shownCount Million.naiveShown
    let kept := Million.shownCount (Million.inkproofShown exts)
    let n := Million.spikes.size
    let axisLabels (p : Reduce.Panel) := Browser.tickLabels (Million.axes p measure)
    let title (p : Reduce.Panel) (text : String) : Label := { text, x := Rat.toFloat p.left, y := Rat.toFloat p.top - 14, font := "bold 14px sans-serif" }
    let labels := axisLabels Million.naivePanel ++ axisLabels Million.inkproofPanel ++
      #[title Million.naivePanel s!"One sample per column: {shown} of {n} spikes shown, {n - shown} lost",
        title Million.inkproofPanel s!"Inkproof, lowest and highest per column: {kept} of {n} spikes shown, {n - kept} lost"]
    pure { commands := Page.bytes 1200 760 (Million.naiveChart measure ++ Million.inkproofChart exts measure), labels }
