/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.CalendarTime

open Inkproof.Web.Host Inkproof.Demos Inkproof

def scene (s : CalendarTime.Spec) (off : Array Bool) : IO Scene := do
  let measure ← measurer "12px sans-serif" s.labelTexts.toArray
  pure { commands := Gpu.frameBytes s.width s.height (s.chart off measure) background,
         labels := Browser.tickLabels (s.axes measure),
         access := Browser.accessOf s.name s.frame (Browser.seriesTraces off [(CalendarTime.red, s.data)]) }

/-- The charts of `timezones-dst` and `months`, by the name a page's chart gives as its source. -/
def run : IO Unit := do
  let dst ← IO.ofExcept CalendarTime.dstSpecs
  let months ← IO.ofExcept (CalendarTime.monthSpec (← Browser.seed))
  let specs := dst ++ [months]
  Browser.registerLegend fun src off => do
    let some s := specs.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    scene s off

end Page.CalendarTime
