/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.HeatmapCells

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.HeatmapCells

def run : IO Unit :=
  Browser.registerPixels fun src px => match src with
    | "cells" =>
      let c := { chart with theme := px.theme }
      Browser.sidedScene px c.labelTexts.toArray [.bottom, .left] c.axes (display · px.theme)
    | src => throw (IO.userError s!"no chart {src}")

end Page.HeatmapCells
