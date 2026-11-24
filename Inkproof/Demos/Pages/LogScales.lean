/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.LogScales

open Inkproof.Web.Host Inkproof.Demos Inkproof

def run : IO Unit :=
  Browser.registerRetained fun src px cache => do
    let some s := LogScales.specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    let measure ← measurer Browser.font s.labelTexts.toArray
    let axes := s.axes measure
    px.drawing cache
      { base := axes.foldl (· ++ ·.display) #[], labels := Browser.tickLabels axes
        parts := Browser.Part.indexed (LogScales.layers.toArray.map s.layerDisplay)
        access := fun off => Browser.accessOf "Log Scales" s.frame (Browser.seriesTraces off (LogScales.layers.map fun l => (l.color, l.data)) (LogScales.layers.map (·.label))) }

end Page.LogScales
