/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof

def main : IO Unit :=
  register "inkproof-chart" fun src => do
    let some s := LogScales2.specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")


    let measure ← measurer "12px sans-serif" s.labelTexts.toArray
    let axes := s.axes measure
    let labels := Browser.tickLabels axes
    pure { commands := Gpu.frameBytes s.width s.height (s.chart measure) background, labels }
