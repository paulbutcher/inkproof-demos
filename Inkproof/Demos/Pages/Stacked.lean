/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Stacked

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Stacked

def run : IO Unit := do
  let seed ← Browser.seed
  register "inkproof-chart" fun
    | "areas" => Browser.frameScene 800 400 areaFrame (areaChart areaFrame)
    | "bars" => Browser.frameScene 800 400 barFrame (barChart seed barFrame)
    | src => throw (IO.userError s!"no chart {src}")

end Page.Stacked
