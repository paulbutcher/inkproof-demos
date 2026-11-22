/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.PathGapClip

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  Browser.registerLegend fun src px off => do
    let some c := PathGapClip.charts.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    Browser.lineScene px c off

end Page.PathGapClip
