/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.SparklinesBars

def main : IO Unit :=
  register "inkproof-chart" fun
    | "split" => Browser.sidedScene width height background #[] [] (fun _ => []) (fun _ => chartSplit)
    | "colored" => Browser.sidedScene width height background #[] [] (fun _ => []) (fun _ => chartColored)
    | src => throw (IO.userError s!"no chart {src}")
