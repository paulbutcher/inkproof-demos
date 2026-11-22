/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.GroupedBars

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.GroupedBars

def run : IO Unit :=
  Browser.registerLegend fun src px off => do
    let some c := (charts.find? (·.1 == src)).map (·.2) | throw (IO.userError s!"no chart {src}")
    Browser.barScene px c (some off)

end Page.GroupedBars
