/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos

def main : IO Unit :=
  register "inkproof-chart" fun src => do
    let some c := Boxes.charts.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    Browser.paneScene c.pane c.shapes
