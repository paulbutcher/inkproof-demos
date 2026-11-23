/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Scatter

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Scatter Inkproof.Scene

def run : IO Unit := do
  let cs := clouds (← Browser.seed)
  let f := cloudsFrame cs
  Browser.registerRetained fun src px cache => match src with
    | "bubble" => do
        let scene ← Browser.sidedScene px background (labelTexts bubbleFrame) [.bottom, .left, .right]
          (bubbleAxes bubbleFrame) (bubbleChart bubbleFrame)
        pure fun _ => pure scene
    | "scatter" => do
        let d ← Browser.frameDrawing f (axisDisplay f) (cs.map (cloudDisplay f)) "Scatter" (Browser.cloudTraces cs)
        px.drawing cache d
    | src => throw (IO.userError s!"no chart {src}")

end Page.Scatter
