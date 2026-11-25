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

/-- Labels without padding: 0, 0.5 and 1 read as written. -/
def trimmed : NumberFormat := { trim := true }

/-- The pixels uPlot keeps between ticks: 50 along an x axis and 30 along a value axis. -/
def xSpacing : Float := 50

def ySpacing : Float := 30

/-- Ticks of a linear axis `extent` pixels long over `lo` to `hi`, at least `spacing` pixels apart at a step of 1, 2, 2.5 or 5 times a power of ten, with their labels. -/
def spacedTicks (lo hi extent spacing : Float) (unit : String := "") : List Float × List String :=
  let ts := spacedLinearTicks stepMultiples lo hi extent spacing
  (ts, ({ trimmed with unit } : NumberFormat).formatAll ts)

theorem spacedTicks_eq (lo hi extent spacing : Float) (unit : String) : spacedTicks lo hi extent spacing unit =
    (spacedLinearTicks stepMultiples lo hi extent spacing,
     ({ trimmed with unit } : NumberFormat).formatAll (spacedLinearTicks stepMultiples lo hi extent spacing)) := rfl

/-- Month names for time axes. -/
def months : List String := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

/-- Dates as 3/29 and 7/17/20, with the 24-hour clock. -/
def numericDates : TimeStyle := { date := .numeric '/' false, contextDate := .numeric '/' false }

/-- Dates as 3/29 and 7/17/20, with the 12-hour clock: 3am, 3:30pm. -/
def twelveHour : TimeStyle := { numericDates with clock := .h12 "am" "pm" }

/-- The ticks of a time axis `extent` pixels long over `lo` to `hi` Unix seconds in the zone whose offsets are `off`, at least `xSpacing` pixels apart at clock intervals, with their labels and the context line of each. -/
def spacedTimeTicks (style : TimeStyle) (off : Int → Int) (lo hi extent : Float) :
    List Float × List String × List (Option String) :=
  let (step, ts) := durationTicksAtSpaced off lo hi extent xSpacing
  (ts, timeTickLabelsAtWith style off months step ts, timeTickContextsAtWith style off months step ts)

theorem spacedTimeTicks_eq (style : TimeStyle) (off : Int → Int) (lo hi extent : Float) : spacedTimeTicks style off lo hi extent =
    ((durationTicksAtSpaced off lo hi extent xSpacing).2,
     timeTickLabelsAtWith style off months (durationTicksAtSpaced off lo hi extent xSpacing).1 (durationTicksAtSpaced off lo hi extent xSpacing).2,
     timeTickContextsAtWith style off months (durationTicksAtSpaced off lo hi extent xSpacing).1 (durationTicksAtSpaced off lo hi extent xSpacing).2) := rfl

/-- The ticks of a time axis over `lo` to `hi` seconds, at clock intervals, about `target` of them, with their labels. -/
def timeTicks (lo hi : Float) (target : Nat) : List Float × List String :=
  let ticks := durationTicks lo hi target
  (ticks, timeTickLabels months (durationStep (hi - lo) target) ticks)

theorem timeTicks_eq (lo hi : Float) (target : Nat) : timeTicks lo hi target =
    (durationTicks lo hi target, timeTickLabels months (durationStep (hi - lo) target) (durationTicks lo hi target)) := rfl

end Inkproof.Demos.Axes
