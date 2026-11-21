/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.LogScales2

open Inkproof.Web.Host Inkproof.Demos Inkproof

def run : IO Unit :=
  Browser.registerLegend fun src off => do
    let some s := LogScales2.specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    let measure ← measurer "12px sans-serif" s.labelTexts.toArray
    let labels := Browser.tickLabels (s.axes measure)
    let traces := Browser.seriesTraces off [(s.stroke, s.data)]
    pure { commands := Gpu.frameBytes s.width s.height (s.chart off measure) background, labels,
           access := Browser.accessOf "Log Scales 2" s.frame traces }

end Page.LogScales2
