/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Stacked

open Inkproof.Web Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Stacked Inkproof

private def traces (ss : Array (Core.Series Rat Rat)) (off : Array Bool) : Array Trace :=
  Browser.seriesTraces off (ss.toList.zipIdx.map fun (s, i) => (colour i, s))

def run : IO Unit := do
  let seed ← Browser.seed
  Browser.registerLegend fun src off => match src with
    | "areas" => Browser.frameScene 800 400 areaFrame (areaChart off areaFrame) "Stacked areas" (traces areaSeries off)
    | "bars" => Browser.frameScene 800 400 barFrame (barChart off seed barFrame) "Stacked bars" (traces (barSeries seed) off)
    | src => throw (IO.userError s!"no chart {src}")

end Page.Stacked
