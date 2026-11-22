/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Scatter

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Scatter Inkproof.Scene

def run : IO Unit := do
  let seed ← Browser.seed
  Browser.registerLegend fun src px off => match src with
    | "bubble" => Browser.sidedScene px background (labelTexts bubbleFrame) [.bottom, .left, .right]
        (bubbleAxes bubbleFrame) (bubbleChart bubbleFrame)
    | "scatter" => do
        let s ← Browser.frameScene px (scatterFrame seed) (scatterChart seed (scatterFrame seed) off)
        pure { s with access := { name := "Scatter", traces := Browser.cloudTraces (clouds seed) off } }
    | src => throw (IO.userError s!"no chart {src}")

end Page.Scatter
