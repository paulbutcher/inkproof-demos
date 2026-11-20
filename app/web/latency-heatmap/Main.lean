/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.LatencyHistogram

private def heatmap (c : Inkproof.Demos.Lines.Chart) (display : (String → Float × Float) → Inkproof.Scene.DisplayList) : IO Inkproof.Web.Host.Scene :=
  Browser.sidedScene c.width c.height background c.labelTexts.toArray [.bottom, .left] c.axes display

def main : IO Unit :=
  register "inkproof-chart" fun
    | "outlined" => Browser.frameScene 1800 600 frame (chart 0 2 frame)
    | "gapped" => Browser.frameScene 1800 600 frame (chart 3 1 frame)
    | "samples" => heatmap LatencyHeatmap.chart LatencyHeatmap.samplesDisplay
    | "buckets" => heatmap LatencyHeatmap.chart LatencyHeatmap.bucketsDisplay
    | src => throw (IO.userError s!"no chart {src}")
