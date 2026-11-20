/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.MultiBars

def main : IO Unit :=
  register "inkproof-chart" fun
    | "builds" => Browser.barScene builds
    | "numeric" => Browser.frameScene 800 400 numeric (numericChart numeric)
    | "benchmark" => Browser.barScene (benchmark false)
    | "benchmark-horizontal" => Browser.barScene (benchmark true)
    | src => throw (IO.userError s!"no chart {src}")
