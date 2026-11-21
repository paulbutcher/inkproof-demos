/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.LogScales

open Inkproof.Web.Host Inkproof.Demos Inkproof

def run : IO Unit :=
  Browser.registerLegend fun src off => do
    let some s := LogScales.specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    let measure ← measurer "12px sans-serif" s.labelTexts.toArray
    let labels := Browser.tickLabels (s.axes measure)
    let traces := Browser.seriesTraces off (LogScales.layers.map fun l => (l.color, l.data))
    pure { commands := Gpu.frameBytes LogScales.width LogScales.height (s.chart off measure) background, labels,
           access := Browser.accessOf "Log Scales" s.frame traces }

end Page.LogScales
