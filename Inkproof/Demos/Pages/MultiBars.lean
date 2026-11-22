/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.MultiBars

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.MultiBars

def run : IO Unit := do
  let seed ← Browser.seed
  Browser.registerLegend fun src px off => match src with
    | "builds" => Browser.barScene px (builds seed)
    | "numeric" => Browser.frameScene px numeric (numericChart seed numeric)
    | "benchmark" => Browser.barScene px (benchmark seed false) (some off)
    | "benchmark-horizontal" => Browser.barScene px (benchmark seed true) (some off)
    | _ => throw (IO.userError s!"no chart {src}")

end Page.MultiBars
