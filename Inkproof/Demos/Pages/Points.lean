/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Demos.Browser

namespace Page.Points

-- A closed term would be evaluated when the module initialises, which every page pays for.
set_option compiler.extract_closed false

open Inkproof.Web Inkproof.Web.Host Inkproof.Scene Inkproof.Demos Inkproof.Demos.Points Inkproof

def run : IO Unit :=
  Browser.registerRetained fun src px cache => do
    let draw (panel : Panel) (parts : Array DisplayList) (series : List (Color × Inkproof.Core.Series Rat Rat)) : IO _ := do
      let d ← Browser.frameDrawing panel.frame (axisDisplay panel.frame) parts "Points" fun _ => #[]
      px.drawing cache { d with access := fun off => Browser.accessOf "Points" panel.frame (Browser.seriesTraces off series) }
    match src with
    | "multi" => draw multi (multiParts multi.frame) [(green, seriesA), (red, seriesB), (blue, seriesC), (orange, seriesD)]
    | "single" => draw single (singleParts true single.frame) [(green, singleSeries)]
    | "dense" => draw singleDense (singleParts false singleDense.frame) [(green, singleSeries)]
    | "sparse" => draw sparseFrame (sparseParts sparseFrame.frame) [(magenta, sparseSeries)]
    | src => throw (IO.userError s!"no chart {src}")

end Page.Points
