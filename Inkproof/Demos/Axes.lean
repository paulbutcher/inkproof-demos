/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Scene

namespace Inkproof.Demos.Axes

open Inkproof.Scale Inkproof.Scene Inkproof.Axis

def style : AxisStyle :=
  ⟨⟨0, .flat ⟨0, 0, 0, 255⟩⟩, 1/2, ⟨0, .flat ⟨0, 0, 0, 255⟩⟩, 1/2, 6, some (⟨0, .flat ⟨0, 0, 0, 30⟩⟩, 1/2), 14⟩

/-- Ten ticks in English, with at least eight pixels between labels. -/
def spec : TickSpec := ⟨.en, 10, 8⟩

/-- The labels of the ticks a linear axis over `lo` to `hi` shows. -/
def linearLabels (lo hi : Float) : List String := tickLabels spec.locale (linearTicks lo hi spec.target)

theorem linearLabels_eq (lo hi : Float) :
    linearLabels lo hi = tickLabels spec.locale (linearTicks lo hi spec.target) := rfl

/-- Month names for time axes. -/
def months : List String := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

/-- The ticks of a time axis over `lo` to `hi` seconds, at clock intervals, about `target` of them, with their labels. -/
def timeTicks (lo hi : Float) (target : Nat) : List Float × List String :=
  let ticks := durationTicks lo hi target
  (ticks, timeTickLabels months (durationStep (hi - lo) target) ticks)

theorem timeTicks_eq (lo hi : Float) (target : Nat) : timeTicks lo hi target =
    (durationTicks lo hi target, timeTickLabels months (durationStep (hi - lo) target) (durationTicks lo hi target)) := rfl

end Inkproof.Demos.Axes
