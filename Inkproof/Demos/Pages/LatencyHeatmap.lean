/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.JS
import Inkproof.Demos.Browser

namespace Page.LatencyHeatmap

open Lasm.JS Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.LatencyHistogram

private def histogram (px : Browser.Pixels) (gap stroke : Rat) (size : Nat := bucket) (offset : Int := 0) : IO Inkproof.Web.Host.Scene :=
  Browser.frameScene px (frame size offset) (fun f m => chart gap stroke f m size offset) "Latencies" #[]
    #[Browser.valueGroup "Bucket" ⟨255, 0, 0, 255⟩ #["From (ms)", "To (ms)", "Count"] ((rows size offset).map (·.1)) ((rows size offset).map (·.2))]

/-- What a slider of the page reads, or `fallback` when it holds no integer. -/
private def slider (id : String) (fallback : Int) : IO Int := do
  let input ← (← (← global).get "document").callMethod "getElementById" #[toJS id] Value
  let text ← input.get "value" String
  match text.toInt? with
  | some k => pure k
  | none =>
    log .warn "slider value is not an integer" [("slider", id), ("value", text), ("using", toString fallback)]
    pure fallback

private def sized : IO (Nat × Int) := do
  pure ((← slider "binsize" bucket).toNat.max 1, ← slider "binoffset" 0)

private def heatmap (px : Browser.Pixels) (display : (String → Float × Float) → Option Inkproof.Scene.Theme → Inkproof.Scene.DisplayList)
    (labels : Array String) (rows : Array (Array Rat)) : IO Inkproof.Web.Host.Scene := do
  let c := { LatencyHeatmap.chart with theme := px.theme }
  let s ← Browser.sidedScene px c.labelTexts.toArray [.bottom, .left] c.axes (display · px.theme)
  let group := Browser.valueGroup "Column" ⟨255, 0, 0, 255⟩ labels LatencyHeatmap.seconds rows
  pure { s with access := Browser.groupsAccess "Latencies" c.frame #[group] }

def run : IO Unit := do
  let sizes ← IO.mkRef (none : Option Browser.Pixels)
  Browser.registerPixels fun src px => match src with
    | "outlined" => do
      sizes.set (some px)
      let (size, offset) ← sized
      histogram px 0 2 size offset
    | "gapped" => histogram px 3 1
    | "samples" => heatmap px (fun m t => LatencyHeatmap.samplesDisplay m t) #["Latencies", "Lowest (ms)", "Highest (ms)"] LatencyHeatmap.sampleRows
    | "buckets" => heatmap px (fun m t => LatencyHeatmap.bucketsDisplay m t) #["Buckets", "Fullest from (ms)", "Its count"] LatencyHeatmap.bucketRows
    | src => throw (IO.userError s!"no chart {src}")
  let document ← (← global).get "document"
  let moved ← Function.ofSyncFn fun _ => do
    let (size, offset) ← sized
    (← document.callMethod "getElementById" #[toJS "cursize"] Value).set "textContent" (toString size)
    (← document.callMethod "getElementById" #[toJS "curoffset"] Value).set "textContent" (toString offset)
    let chart ← document.callMethod "getElementById" #[toJS "outlined"] Value
    if let some px ← sizes.get then setScene chart (← histogram px 0 2 size offset)
    return .undefined
  for id in ["binsize", "binoffset"] do
    (← document.callMethod "getElementById" #[toJS id] Value).callMethod "addEventListener" #[toJS "input", toJS moved] Unit

end Page.LatencyHeatmap
