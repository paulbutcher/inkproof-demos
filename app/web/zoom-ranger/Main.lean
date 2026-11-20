/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage

open Inkproof.Demos

def main : IO Unit := do
  ZoomPage.mount Linked.rangerCharts
  ZoomPage.selectWhenDrawn "ranger-overview" (Linked.rangerStart, Linked.rangerEnd)
