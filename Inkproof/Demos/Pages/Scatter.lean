/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Scatter

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Scatter Inkproof.Scene

def run : IO Unit := do
  let seed ← Browser.seed
  Browser.registerLegend fun src off => match src with
    | "bubble" => Browser.sidedScene 1920 600 background (labelTexts bubbleFrame) [.bottom, .left, .right]
        (bubbleAxes bubbleFrame) (bubbleChart bubbleFrame)
    | "scatter" => do
        let s ← Browser.frameScene 1920 600 (scatterFrame seed) (scatterChart seed (scatterFrame seed) off)
        pure { s with access := { name := "Scatter", traces := Browser.cloudTraces (clouds seed) off } }
    | src => throw (IO.userError s!"no chart {src}")

end Page.Scatter
