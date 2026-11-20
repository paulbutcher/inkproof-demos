/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.HeatmapCells

def main : IO Unit :=
  register "inkproof-chart" fun
    | "cells" => Browser.sidedScene chart.width chart.height background chart.labelTexts.toArray [.bottom, .left] chart.axes display
    | src => throw (IO.userError s!"no chart {src}")
