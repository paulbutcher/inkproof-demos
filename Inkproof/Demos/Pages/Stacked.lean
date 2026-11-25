/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Stacked

open Inkproof.Web Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Stacked Inkproof

private def traces (ss : Array (Core.Series Rat Rat)) (off : Array Bool) (names : List String := []) : Array Trace :=
  Browser.seriesTraces off (ss.toList.zipIdx.map fun (s, i) => (colour i, s)) names

def run : IO Unit := do
  let seed ← Browser.seed
  Browser.registerLegend fun src px off => match src with
    | "areas" => Browser.frameScene px areaFrame (areaChart off) "Stacked areas" (traces areaSeries off)
    | "bars" => Browser.frameScene px barFrame (barChart off seed) "Stacked bars" (traces (barSeries seed) off barNames)
    | src => throw (IO.userError s!"no chart {src}")

end Page.Stacked
