/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Sparklines

def main : IO Unit :=
  register "inkproof-chart" fun src => do
    let some vals := named? src | throw (IO.userError s!"no sparkline {src}")
    Browser.sidedScene width height pink #[] [] (fun _ => []) (fun _ => chart vals)
