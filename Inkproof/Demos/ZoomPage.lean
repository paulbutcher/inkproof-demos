/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Web.Access
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.SceneCache
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser
import Inkproof.Demos.Zoom

namespace Inkproof.Demos.ZoomPage

open Lasm.JS Inkproof.Web Inkproof.Web.Host Inkproof.Gpu Inkproof.Viewport Inkproof.Demos

/-- The chart `full` with its bounds fixed, so that hiding a line changes neither its range nor its pieces. -/
def fixed (full : Zoom.Chart) : Zoom.Chart := { full with bounds := some full.ranges }

/-- The pieces of `full` tessellated once for `px`, to give to `sceneOf`. -/
def retain (full : Zoom.Chart) (px : Browser.Pixels) : Array Gpu.Layer := (fixed full).retain px.ratio

/-- The scene of `full` under `v` with the lines in `off` hidden, drawn from `layers` retained by `retain full px` and the buffers `cache` keeps on the GPU. -/
def sceneOf (full : Zoom.Chart) (name : String) (cache : SceneCache) (px : Browser.Pixels) (layers : Array Gpu.Layer)
    (off : Array Bool) (v : View Float) : IO Scene := do
  let c := fixed full
  let f := c.viewFrame v
  let measure ← measurer Browser.font (texts f ++ (c.marks.map (·.label)).toArray)
  let cmds ← cache.build fun old first => pure (c.commands old first v measure px.backing px.ratio layers off)
  let points := ((c.lines.zipIdx.filter fun (_, i) => !off.getD i false).map (·.1.xs.size)).foldl max 0
  let traces := (full.lines.zipIdx.map fun (l, i) =>
    { name := (Zoom.legendNames name).getD i "Value", color := s!"rgb({l.color.r},{l.color.g},{l.color.b})",
      xs := l.xs.map Rat.toFloat, ys := l.ys.map Rat.toFloat, hidden := off.getD i false : Trace }).toArray
  pure { commands := ⟨(encode cmds).toArray⟩, labels := Browser.tickLabels (axes f measure) ++
           (c.markTexts f measure).toArray.map fun (text, x, y) => { text, x := Rat.toFloat x, y := Rat.toFloat y, baseline := .top },
         access := { name, series := (c.lines.map fun _ => "line").toArray, points, view := some c.config, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top), traces } }

/-- Draw each named chart, and draw it again under the range the pointer or keys move it to. -/
def mount (charts : List (String × Zoom.Chart)) : IO Unit := do
  let caches ← charts.mapM fun (name, c) => do pure (name, c, ← SceneCache.new, ← IO.mkRef (View.home c.config), ← IO.mkRef (Array.replicate c.lines.length false))
  let sizes ← IO.mkRef (({} : Std.HashMap String (Browser.Pixels × Array Gpu.Layer)))
  let find (name : String) := caches.find? (·.1 == name)
  Browser.registerPixels (buttons := true) fun name px => do
    let some (_, c, cache, view, off) := find name | throw (IO.userError s!"no chart {name}")
    let layers := retain c px
    sizes.modify (·.insert name (px, layers))
    sceneOf c name cache px layers (← off.get) (← view.get)
  let redraw (restore : Bool) (args : Array Data) : IO Data := do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      let name ← el.callMethod "getAttribute" #[toJS "src"] String
      if let some (_, c, cache, view, off) := find name then
        unless restore do view.set (← viewOf (← event.get "detail" Value))
        if let some (px, layers) := (← sizes.get).get? name then setScene el (← sceneOf c name cache px layers (← off.get) (← view.get))
    return .undefined
  let doc ← (← global).get "document"
  for (event, restore) in [("inkproof-view", false), ("inkproof-contextrestored", true)] do
    doc.callMethod "addEventListener" #[toJS event, toJS (← Function.ofSyncFn (redraw restore))] Unit
  let toggled ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      let name ← el.callMethod "getAttribute" #[toJS "src"] String
      let detail ← event.get "detail" Value
      let series ← detail.get "series" Nat
      let hide ← detail.get "hidden" Bool
      if let some (_, c, cache, view, off) := find name then
        off.modify fun h => h.setIfInBounds series hide
        if let some (px, layers) := (← sizes.get).get? name then setScene el (← sceneOf c name cache px layers (← off.get) (← view.get))
    return .undefined
  doc.callMethod "addEventListener" #[toJS "inkproof-series", toJS toggled] Unit
  let reading ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let (x, y) ← pointerOf (← event.get "detail" Value)
      if let .ref el _ := ← doc.callMethod "getElementById" #[toJS "reading"] Data then
        el.set "textContent" s!"x = {showFloat x}, y = {showFloat y}"
    return .undefined
  doc.callMethod "addEventListener" #[toJS "inkproof-pointer", toJS reading] Unit

/-- Select the x range `range` on the chart with id `id` the first time it is drawn, so that a range selector starts with a band to move. -/
def selectWhenDrawn (id : String) (range : Float × Float) : IO Unit := do
  let doc ← (← global).get "document"
  let done ← IO.mkRef false
  let listener ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      if !(← done.get) && (← el.get "id" String) == id then
        done.set true
        setSelection el (some range)
    return .undefined
  doc.callMethod "addEventListener" #[toJS "inkproof-draw", toJS listener] Unit

end Inkproof.Demos.ZoomPage
