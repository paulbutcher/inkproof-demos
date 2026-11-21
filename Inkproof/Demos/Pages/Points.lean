/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Demos.Browser

namespace Page.Points

open Inkproof.Web Inkproof.Web.Host Inkproof.Scene Inkproof.Demos Inkproof.Demos.Points Inkproof

def run : IO Unit :=
  Browser.registerLegend fun src off => match src with
    | "multi" => Browser.frameScene multi.width multi.height multi.frame (multiChart off multi.frame) "Points"
        (Browser.seriesTraces off [(green, seriesA), (red, seriesB), (blue, seriesC), (orange, seriesD)])
    | "single" => Browser.frameScene single.width single.height single.frame (singleChart off single.frame · true) "Points"
        (Browser.seriesTraces off [(green, singleSeries)])
    | "dense" => Browser.frameScene singleDense.width singleDense.height singleDense.frame (singleChart off singleDense.frame · false) "Points"
        (Browser.seriesTraces off [(green, singleSeries)])
    | "sparse" => Browser.frameScene sparseFrame.width sparseFrame.height sparseFrame.frame (sparseChart off sparseFrame.frame) "Points"
        (Browser.seriesTraces off [(magenta, sparseSeries)])
    | src => throw (IO.userError s!"no chart {src}")

end Page.Points
