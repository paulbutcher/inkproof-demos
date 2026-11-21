/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.MultiBars

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.MultiBars

def run : IO Unit := do
  let seed ← Browser.seed
  register "inkproof-chart" fun
    | "builds" => Browser.barScene (builds seed)
    | "numeric" => Browser.frameScene 800 400 numeric (numericChart seed numeric)
    | "benchmark" => Browser.barScene (benchmark seed false)
    | "benchmark-horizontal" => Browser.barScene (benchmark seed true)
    | src => throw (IO.userError s!"no chart {src}")

end Page.MultiBars
