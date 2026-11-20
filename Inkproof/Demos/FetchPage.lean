/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Web.Host.Chart
import Inkproof.Web.Host.Tiles
import Inkproof.Demos.Linked
import Inkproof.Demos.ZoomPage

namespace Inkproof.Demos.FetchPage

open Std.Async Lasm.JS Inkproof.Web Inkproof.Web.Host Inkproof.Viewport Inkproof.Demos

/-- The chart of the points that the server returned for `view`, drawn under it: the whole series at one point in twenty when `view` shows all of it, else the samples of the visible range and a margin. -/
private def fetchFor (view : View Float) : Async (Option Zoom.Chart) := do
  let full := view.x.start ≤ 0 && view.x.start + view.x.span ≥ (Linked.samples - 1).toFloat
  let (stride, first, count) := if full then (20, 0, Linked.samples / 20) else
    let (lo, n) := Linked.windowOf view.x.start (view.x.start + view.x.span)
    (1, lo, n)
  if count == 0 then return none
  let url := if full then "../data/zoom-fetch-coarse.bin" else "../data/zoom-fetch-fine.bin"
  let some body ← (try (some <$> fetchTile url (some (first, count))) catch _ => pure none) | return none
  pure (some (Linked.fetched (Linked.points stride (first / stride) body)))

/-- Draw the `zoom-fetch` chart from data fetched for the range it shows, and fetch again whenever the pointer or keys change the range. -/
def mount : IO Unit := do
  let states ← IO.mkRef ({} : Std.HashMap String ZoomPage.State)
  let current ← IO.mkRef (Linked.fetched #[])
  let latest ← IO.mkRef 0
  let name := "zoom-fetch"
  register "inkproof-chart" fun _ => do
    ZoomPage.sceneOf (← current.get) name 0 states (View.home (← current.get).config)
  let doc ← (← global).get "document"
  let update (view : View Float) : IO Unit := do
    let ticket := (← latest.get) + 1
    latest.set ticket
    discard <| Std.Async.Async.toIO (do
      let some chart ← fetchFor view | return
      if (← latest.get) == ticket then
        current.set chart
        states.modify (·.erase name)
        if let .ref el _ := ← doc.callMethod "getElementById" #[toJS "chart"] Data then
          setScene el (← ZoomPage.sceneOf chart name 0 states view))
  let onView ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      update (← ZoomPage.viewOf (← event.get "detail" Value))
    return .undefined
  doc.callMethod "addEventListener" #[toJS "inkproof-view", toJS onView] Unit
  update (View.home (Linked.fetched #[]).config)
  let onClick ← Function.ofSyncFn fun args => do
    if let some (Data.ref event _) := args[0]? then
      let hit ← (← event.get "target" Value).callMethod "closest" #[toJS "button[data-reset]"] Data
      if let .ref _ _ := hit then
        if let .ref el _ := ← doc.callMethod "getElementById" #[toJS "chart"] Data then apply el .reset
    return .undefined
  doc.callMethod "addEventListener" #[toJS "click", toJS onClick] Unit

end Inkproof.Demos.FetchPage
