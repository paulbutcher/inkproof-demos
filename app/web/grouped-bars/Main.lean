/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.GroupedBars

def main : IO Unit :=
  register "inkproof-chart" fun src => do
    let some c := (charts.find? (·.1 == src)).map (·.2) | throw (IO.userError s!"no chart {src}")
    Browser.barScene c
