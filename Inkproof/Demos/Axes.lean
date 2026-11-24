/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Scene

namespace Inkproof.Demos.Axes

open Inkproof.Scale Inkproof.Scene Inkproof.Axis

/-- The text of axis labels, and of every other label a page draws. -/
def text : TextStyle := { size := 12 }

/-- How numbers are written in bar labels; a page gives its legend and tooltip the same words in `number-format`. -/
def numbers : NumberFormat := {}

/-- uPlot's default axis: no axis line, and ticks and gridlines of the same faint 2px stroke. -/
def style : AxisStyle :=
  let faint : Paint := ⟨0, .flat ⟨0, 0, 0, 18⟩⟩
  { tick := faint, tickHalfWidth := 1, tickLength := 10, grid := some (faint, 1), labelGap := 5, showLine := false, labelText := text }

/-- uPlot's minor gridlines: a one pixel stroke, fainter than the major grid. -/
def minorGrid (positions : List Float) : MinorGrid Float := ⟨⟨0, .flat ⟨0, 0, 0, 8⟩⟩, 1 / 2, positions⟩

theorem minorGrid_positions (positions : List Float) : (minorGrid positions).positions = positions := rfl

/-- Half the width of a series' stroke, one pixel in all: uPlot's default. -/
def strokeHalfWidth : Rat := 1 / 2

theorem style_spec : style.showLine = false ∧ style.tickLength = 10 ∧ style.tickHalfWidth = 1 ∧
    style.grid.map (·.2) = some 1 := ⟨rfl, rfl, rfl, rfl⟩

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
