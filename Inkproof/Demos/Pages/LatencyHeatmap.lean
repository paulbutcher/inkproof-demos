/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.LatencyHeatmap

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.LatencyHistogram

private def histogram (px : Browser.Pixels) (gap stroke : Rat) : IO Inkproof.Web.Host.Scene :=
  Browser.frameScene px frame (chart gap stroke) "Latencies" #[]
    #[Browser.valueGroup "Bucket" ⟨255, 0, 0, 255⟩ #["From (ms)", "To (ms)", "Count"] (rows.map (·.1)) (rows.map (·.2))]

private def heatmap (px : Browser.Pixels) (display : (String → Float × Float) → Option Inkproof.Scene.Theme → Inkproof.Scene.DisplayList)
    (labels : Array String) (rows : Array (Array Rat)) : IO Inkproof.Web.Host.Scene := do
  let c := { LatencyHeatmap.chart with theme := px.theme }
  let s ← Browser.sidedScene px c.labelTexts.toArray [.bottom, .left] c.axes (display · px.theme)
  let group := Browser.valueGroup "Column" ⟨255, 0, 0, 255⟩ labels LatencyHeatmap.seconds rows
  pure { s with access := Browser.groupsAccess "Latencies" c.frame #[group] }

def run : IO Unit :=
  Browser.registerPixels fun src px => match src with
    | "outlined" => histogram px 0 2
    | "gapped" => histogram px 3 1
    | "samples" => heatmap px (fun m t => LatencyHeatmap.samplesDisplay m t) #["Latencies", "Lowest (ms)", "Highest (ms)"] LatencyHeatmap.sampleRows
    | "buckets" => heatmap px (fun m t => LatencyHeatmap.bucketsDisplay m t) #["Buckets", "Fullest from (ms)", "Its count"] LatencyHeatmap.bucketRows
    | src => throw (IO.userError s!"no chart {src}")

end Page.LatencyHeatmap
