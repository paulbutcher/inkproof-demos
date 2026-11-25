/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser

namespace Page.Million

open Inkproof.Web.Host Inkproof.Demos Inkproof

def run : IO Unit :=
  Browser.registerPixels fun _ px => do
    let numbers := (List.range 12).map (fun (i : Nat) => toString (i * 100000)) ++ (List.range 15).map (fun (i : Nat) => toString ((i : Int) * 100 - 300))
    let measure ← measurer Browser.font numbers.toArray
    let exts := Million.columnExtents Million.pyramid
    let shown := Million.shownCount Million.naiveShown
    let kept := Million.shownCount (Million.inkproofShown exts)
    let n := Million.spikes.size
    let axisLabels (p : Frame) := Browser.tickLabels (axes { p with theme := px.theme } measure)
    let title (p : Frame) (text : String) : Label := { text, x := Rat.toFloat p.left, y := Rat.toFloat p.top - 14, font := "bold 14px sans-serif" }
    let labels := axisLabels Million.naivePanel ++ axisLabels Million.inkproofPanel ++
      #[title Million.naivePanel s!"One sample per column: {shown} of {n} spikes shown, {n - shown} lost",
        title Million.inkproofPanel s!"Inkproof, lowest and highest per column: {kept} of {n} spikes shown, {n - kept} lost"]
    pure { commands := px.frameBytes (Million.naiveChart measure px.theme ++ Million.inkproofChart exts measure px.theme) px.background, labels }

end Page.Million
