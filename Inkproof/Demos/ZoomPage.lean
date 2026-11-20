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

/-- The scene of `c` under `v`, built from the buffers `cache` keeps on the GPU. -/
def sceneOf (c : Zoom.Chart) (name : String) (cache : SceneCache) (v : View Float) : IO Scene := do
  let f := c.viewFrame v
  let measure ← measurer "12px sans-serif" (texts f)
  let cmds ← cache.build fun old first => pure (c.commands old first v measure)
  let points := (c.lines.map (·.xs.size)).foldl max 0
  pure { commands := ⟨(encode cmds).toArray⟩, labels := Browser.tickLabels (axes f measure),
         access := { name, series := (c.lines.map fun _ => "line").toArray, points, view := some c.config, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top) } }

/-- Draw each named chart, and draw it again under the range the pointer or keys move it to. -/
def mount (charts : List (String × Zoom.Chart)) : IO Unit := do
  let caches ← charts.mapM fun (name, c) => do pure (name, c, ← SceneCache.new, ← IO.mkRef (View.home c.config))
  let find (name : String) := caches.find? (·.1 == name)
  register "inkproof-chart" (buttons := true) fun name => do
    let some (_, c, cache, view) := find name | throw (IO.userError s!"no chart {name}")
    sceneOf c name cache (← view.get)
  let redraw (restore : Bool) (args : Array Data) : IO Data := do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      let name ← el.callMethod "getAttribute" #[toJS "src"] String
      if let some (_, c, cache, view) := find name then
        unless restore do view.set (← viewOf (← event.get "detail" Value))
        setScene el (← sceneOf c name cache (← view.get))
    return .undefined
  let doc ← (← global).get "document"
  for (event, restore) in [("inkproof-view", false), ("inkproof-contextrestored", true)] do
    doc.callMethod "addEventListener" #[toJS event, toJS (← Function.ofSyncFn (redraw restore))] Unit
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
