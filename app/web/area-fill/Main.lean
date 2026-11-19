/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Web.Host.Chart

open Inkproof.Web.Host Inkproof.Demos

def main : IO Unit :=
  register "inkproof-chart" fun _ =>
    pure { commands := Page.bytes 1200 600 (AreaFill.chart AreaFill.frame) }
