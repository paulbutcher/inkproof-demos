/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Demos.Browser

namespace Page.ArcsinhScales

open Lasm.JS Inkproof.Web Inkproof.Web.Host Inkproof.Demos Inkproof

/-- The slider's position, as the integer power of ten it stands for. -/
def position : IO Int := do
  let input ← (← (← global).get "document").callMethod "getElementById" #[toJS "linthresh"] Value
  let text ← input.get "value" String
  match text.toInt? with
  | some k => pure k
  | none =>
    log .warn "threshold slider value is not an integer, using 0" [("value", text)]
    pure 0

def scene (px : Browser.Pixels) (k : Int) (off : Array Bool) : IO Scene := do
  let measure ← measurer Browser.font ArcsinhScales.labelTexts.toArray
  pure { commands := px.frameBytes (ArcsinhScales.chart k off measure px.theme) px.background,
         labels := Browser.tickLabels (ArcsinhScales.axes k measure px.theme),
         access := Browser.accessOf "ArcSinh Y Scale" ArcsinhScales.frame (Browser.seriesTraces off [(ArcsinhScales.blue, ArcsinhScales.data)]) }

def run : IO Unit := do
  let hidden ← IO.mkRef (#[] : Array Bool)
  let sizes ← IO.mkRef (none : Option Browser.Pixels)
  Browser.registerLegend fun _ px off => do
    hidden.set off
    sizes.set (some px)
    scene px (← position) off
  let document ← (← global).get "document"
  let moved ← Function.ofSyncFn fun _ => do
    let k ← position
    let label ← document.callMethod "getElementById" #[toJS "thresh-label"] Value
    label.set "textContent" s!"Linear threshold: {Inkproof.Web.showFloat (Rat.toFloat (ArcsinhScales.threshold k))}"
    let chart ← document.callMethod "querySelector" #[toJS "inkproof-chart"] Value
    if let some px ← sizes.get then setScene chart (← scene px k (← hidden.get))
    return .undefined
  let input ← document.callMethod "getElementById" #[toJS "linthresh"] Value
  input.callMethod "addEventListener" #[toJS "input", toJS moved] Unit

end Page.ArcsinhScales
