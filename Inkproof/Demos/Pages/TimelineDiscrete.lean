/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.TimelineDiscrete

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  Browser.registerPixels fun src px => do
    let some c := Timeline.charts.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    Browser.timelineScene px c

end Page.TimelineDiscrete
