/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Web.Access
import Inkproof.Demos.Browser

open Lasm.JS Inkproof.Web Inkproof.Web.Host Inkproof.Demos Inkproof

def scene (seed : Nat) (hidden : Array Bool) : IO Scene := do
  let width ← Browser.windowWidth
  let f := AreaFill.frame width
  let numbers := (List.range 30).map (fun i => toString i) ++ (List.range 25).map (fun (i : Nat) => toString ((i : Int) - 12))
  let measure ← measurer "12px sans-serif" numbers.toArray
  let labels := Browser.tickLabels (axes f measure)
  let traces := (AreaFill.colors.zipIdx.map fun ((stroke, _), i) =>
    let s := AreaFill.pageSeries seed i
    { name := s!"Series {i + 1}", color := s!"rgb({stroke.r},{stroke.g},{stroke.b})", hidden := hidden.getD i false,
      xs := s.xs.map Rat.toFloat, ys := s.values.map fun y => (y.getD 0).toFloat : Trace }).toArray
  pure { commands := Gpu.frameBytes width (AreaFill.height width) (AreaFill.chart seed hidden f measure) background, labels,
         access := { name := "Area Fill", series := traces.map fun _ => "line", points := 30, view := some (AreaFill.config f),
                     plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces } }

def main : IO Unit := do
  let seed ← Browser.seed
  let hidden ← IO.mkRef (Array.replicate AreaFill.colors.length false)
  register "inkproof-chart" fun _ => do scene seed (← hidden.get)
  let toggled ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let detail ← event.get "detail" Value
      let series ← detail.get "series" Nat
      let hide ← detail.get "hidden" Bool
      hidden.modify fun h => h.setIfInBounds series hide
      setScene (← event.get "target" Value) (← scene seed (← hidden.get))
    return .undefined
  (← (← global).get "document").callMethod "addEventListener" #[toJS "inkproof-series", toJS toggled] Unit
