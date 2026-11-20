/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Scatter Inkproof.Scene

def main : IO Unit :=
  register "inkproof-chart" fun
    | "bubble" => Browser.sidedScene 1920 600 background (labelTexts bubbleFrame) [.bottom, .left, .right]
        (bubbleAxes bubbleFrame) (bubbleChart bubbleFrame)
    | "scatter" => Browser.frameScene 1920 600 scatterFrame (scatterChart scatterFrame)
    | src => throw (IO.userError s!"no chart {src}")
