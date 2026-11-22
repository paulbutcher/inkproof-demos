/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.LatencyHeatmap

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.LatencyHistogram

private def heatmap (px : Browser.Pixels) (c : Inkproof.Demos.Lines.Chart) (display : (String → Float × Float) → Inkproof.Scene.DisplayList) : IO Inkproof.Web.Host.Scene :=
  Browser.sidedScene px background c.labelTexts.toArray [.bottom, .left] c.axes display

def run : IO Unit :=
  Browser.registerPixels fun src px => match src with
    | "outlined" => Browser.frameScene px frame (chart 0 2 frame)
    | "gapped" => Browser.frameScene px frame (chart 3 1 frame)
    | "samples" => heatmap px LatencyHeatmap.chart LatencyHeatmap.samplesDisplay
    | "buckets" => heatmap px LatencyHeatmap.chart LatencyHeatmap.bucketsDisplay
    | src => throw (IO.userError s!"no chart {src}")

end Page.LatencyHeatmap
