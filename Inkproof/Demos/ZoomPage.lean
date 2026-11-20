/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Measure
import Inkproof.Demos.Browser
import Inkproof.Demos.Zoom

namespace Inkproof.Demos.ZoomPage

open Lasm.JS Inkproof.Web Inkproof.Web.Host Inkproof.Gpu Inkproof.Viewport Inkproof.Demos

/-- What a zooming chart keeps between frames: the buffers on the GPU, the context they were uploaded under, and the view last drawn. -/
private structure State where
  cache : Cache
  generation : Nat
  view : View Float
  drawn : Bool

/-- The scene of `c` under `v`. Each chart numbers its buffers from its own range, since every chart draws on one context. -/
private def sceneOf (c : Zoom.Chart) (name : String) (base : Nat) (states : IO.Ref (Std.HashMap String State)) (v : View Float) : IO Scene := do
  let f := c.viewFrame v
  let measure ← measurer "12px sans-serif" (texts f)
  let generation ← contextGeneration
  let old := (← states.get)[name]?
  let kept := old.filter (·.generation == generation)
  let (cache, cmds) := c.commands (kept.map (·.cache) |>.getD { next := base }) (!(kept.any (·.drawn))) v measure
  states.modify (·.insert name { cache, generation, view := v, drawn := true })
  let points := (c.lines.map (·.xs.size)).foldl max 0
  pure { commands := ⟨(encode cmds).toArray⟩, labels := Browser.tickLabels (axes f measure),
         access := { name, series := (c.lines.map fun _ => "line").toArray, points, view := some c.config, plotOrigin := (Rat.toFloat f.left, Rat.toFloat f.top) } }

private def viewOf (detail : Value) : IO (View Float) := do
  let x0 ← detail.get "xStart" Float
  let x1 ← detail.get "xEnd" Float
  let y0 ← detail.get "yStart" Float
  let y1 ← detail.get "yEnd" Float
  pure ⟨⟨x0, x1 - x0⟩, ⟨y0, y1 - y0⟩⟩

/-- Draw each named chart, and draw it again under the range the pointer or keys move it to. A button with `data-reset` naming a chart's id returns that chart to its full range. -/
def mount (charts : List (String × Zoom.Chart)) : IO Unit := do
  let states ← IO.mkRef ({} : Std.HashMap String State)
  let find (name : String) : Option (Nat × Zoom.Chart) :=
    (charts.zipIdx.find? (·.1.1 == name)).map fun ((_, c), i) => (i * 1000000, c)
  register "inkproof-chart" fun name => do
    let some (base, c) := find name | throw (IO.userError s!"no chart {name}")
    sceneOf c name base states (View.home c.config)
  let redraw (restore : Bool) (args : Array Data) : IO Data := do
    if let some (Data.ref event _) := args[0]? then
      let el ← event.get "target" Value
      let name ← el.callMethod "getAttribute" #[toJS "src"] String
      if let some (base, c) := find name then
        let v ← if restore then
            pure ((← states.get)[name]?.map (·.view) |>.getD (View.home c.config))
          else viewOf (← event.get "detail" Value)
        setScene el (← sceneOf c name base states v)
    return .undefined
  let doc ← (← global).get "document"
  let click ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let hit ← (← event.get "target" Value).callMethod "closest" #[toJS "button[data-reset]"] Data
      if let .ref button _ := hit then
        let id ← button.callMethod "getAttribute" #[toJS "data-reset"] String
        if let .ref el _ := ← doc.callMethod "getElementById" #[toJS id] Data then apply el .reset
    return .undefined
  doc.callMethod "addEventListener" #[toJS "click", toJS click] Unit
  for (event, restore) in [("inkproof-view", false), ("inkproof-contextrestored", true)] do
    doc.callMethod "addEventListener" #[toJS event, toJS (← Function.ofSyncFn (redraw restore))] Unit

end Inkproof.Demos.ZoomPage
