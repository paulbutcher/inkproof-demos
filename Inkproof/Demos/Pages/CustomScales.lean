/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.CustomScales

open Inkproof.Web.Host Inkproof.Demos Inkproof

def run : IO Unit :=
  Browser.registerLegend fun src px off => do
    let some s := CustomScales.specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    let measure ← measurer Browser.font s.labelTexts.toArray
    pure { commands := px.frameBytes (s.chart off measure) background,
           labels := Browser.tickLabels (s.axes measure),
           access := Browser.accessOf "Custom Scales" s.frame (Browser.seriesTraces off CustomScales.layers) }

end Page.CustomScales
