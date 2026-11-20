/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

open Inkproof.Web.Host Inkproof.Demos

def main : IO Unit :=
  register "inkproof-chart" fun
    | "gold" => Browser.paneScene Candles.pane Candles.shapes
    | src => throw (IO.userError s!"no chart {src}")
