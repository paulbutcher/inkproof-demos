/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage

namespace Page.ZoomRanger

open Inkproof.Demos

def run : IO Unit := do
  ZoomPage.mount Linked.rangerCharts
  ZoomPage.selectWhenDrawn "ranger-overview" (Linked.rangerStart, Linked.rangerEnd)

end Page.ZoomRanger
