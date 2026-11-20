/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Stacked

def main : IO Unit :=
  register "inkproof-chart" fun
    | "areas" => Browser.frameScene 800 400 areaFrame (areaChart areaFrame)
    | "bars" => Browser.frameScene 800 400 barFrame (barChart barFrame)
    | src => throw (IO.userError s!"no chart {src}")
