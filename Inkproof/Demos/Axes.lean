/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Scale
import Inkproof.Scene

namespace Inkproof.Demos.Axes

open Inkproof.Scale Inkproof.Scene Inkproof.Axis

def style : AxisStyle :=
  ⟨⟨0, ⟨0, 0, 0, 255⟩⟩, 1/2, ⟨0, ⟨0, 0, 0, 255⟩⟩, 1/2, 6, some (⟨0, ⟨0, 0, 0, 30⟩⟩, 1/2), 14⟩

/-- A pixel position as the exact number the axis projects it to; a position that is not finite maps to zero. -/
def plane (p : Float) : Rat := (Inkproof.Float.Float.toRat p).getD 0

/-- The labels to keep on an axis of `side`: vertical axes span labels by height and take positions in either order. -/
def labelLayout (side : Side) (measure : String → Float × Float) (ticks : List (Float × String)) :
    Layout (Float × String) :=
  match side with
  | .left | .right => let (n, kept) := layoutLabelsVertical measure 8 ticks; ⟨.horizontal, n, kept⟩
  | _ => layoutLabels measure 8 ticks

theorem labelLayout_eq (side : Side) (measure : String → Float × Float) (ticks : List (Float × String)) :
    labelLayout side measure ticks =
      match side with
      | .left | .right => let (n, kept) := layoutLabelsVertical measure 8 ticks; ⟨.horizontal, n, kept⟩
      | _ => layoutLabels measure 8 ticks := rfl

/-- The axis of `side` of `plot` with a tick at each value of `ticks`, labelled by `labels`, placed at `pixel` of it and drawn in `look`. -/
def withTicks (side : Side) (plot : Rect) (measure : String → Float × Float) (pixel : Float → Float)
    (ticks : List Float) (labels : List String) (look : AxisStyle := style) : AxisDrawing :=
  let placed := (ticks.zip labels).map fun (v, l) => (pixel v, l)
  compileAxis side plot plane look (placed.map (·.1)) (labelLayout side measure placed)

/-- The labels of the ticks `linear` draws on the range `lo` to `hi`. -/
def linearLabels (lo hi : Float) : List String := tickLabels .en (linearTicks lo hi 10)

/-- The axis of `side` of `plot` showing the data range `lo` to `hi`, which lies between `start` and `stop` pixels along the plot. -/
def linear (side : Side) (plot : Rect) (measure : String → Float × Float) (lo hi start stop : Float) :
    AxisDrawing :=
  withTicks side plot measure (Linear.mk lo hi start stop).map (linearTicks lo hi 10) (linearLabels lo hi)

/-- The axis of `side` of `plot` for the log scale from `lo` to `hi` (taking logarithms with `log`) onto `start` to `stop` pixels, with a tick at each of `ticks`. -/
def logarithmic (log : Float → Float) (side : Side) (plot : Rect) (measure : String → Float × Float)
    (lo hi start stop : Float) (ticks : List Float) (labels : List String) : AxisDrawing :=
  withTicks side plot measure (Log.map log ⟨lo, hi, start, stop⟩) ticks labels

/-- Month names for time axes. -/
def months : List String := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

/-- The ticks of a time axis over `lo` to `hi` seconds, at clock intervals, about `target` of them, with their labels. -/
def timeTicks (lo hi : Float) (target : Nat) : List Float × List String :=
  let ticks := durationTicks lo hi target
  (ticks, timeTickLabels months (durationStep (hi - lo) target) ticks)

theorem timeTicks_eq (lo hi : Float) (target : Nat) : timeTicks lo hi target =
    (durationTicks lo hi target, timeTickLabels months (durationStep (hi - lo) target) (durationTicks lo hi target)) := rfl

/-- The axis of `side` of `plot` showing the Unix times `lo` to `hi`, which lie between `start` and `stop` pixels along the plot. -/
def time (side : Side) (plot : Rect) (measure : String → Float × Float) (target : Nat) (lo hi start stop : Float) : AxisDrawing :=
  let (ticks, labels) := timeTicks lo hi target
  withTicks side plot measure (Linear.mk lo hi start stop).map ticks labels

theorem time_eq (side : Side) (plot : Rect) (measure : String → Float × Float) (target : Nat) (lo hi start stop : Float) :
    time side plot measure target lo hi start stop =
      withTicks side plot measure (Linear.mk lo hi start stop).map (timeTicks lo hi target).1 (timeTicks lo hi target).2 := rfl

theorem plane_eq (p : Float) : plane p = (Inkproof.Float.Float.toRat p).getD 0 := rfl

theorem withTicks_eq (side : Side) (plot : Rect) (measure : String → Float × Float) (pixel : Float → Float)
    (ticks : List Float) (labels : List String) (look : AxisStyle) :
    withTicks side plot measure pixel ticks labels look =
      let placed := (ticks.zip labels).map fun (v, l) => (pixel v, l)
      compileAxis side plot plane look (placed.map (·.1)) (labelLayout side measure placed) := rfl

theorem linear_eq (side : Side) (plot : Rect) (measure : String → Float × Float) (lo hi start stop : Float) :
    linear side plot measure lo hi start stop =
      withTicks side plot measure (Linear.mk lo hi start stop).map (linearTicks lo hi 10)
        (linearLabels lo hi) := rfl

theorem logarithmic_eq (log : Float → Float) (side : Side) (plot : Rect) (measure : String → Float × Float)
    (lo hi start stop : Float) (ticks : List Float) (labels : List String) :
    logarithmic log side plot measure lo hi start stop ticks labels =
      withTicks side plot measure (Log.map log ⟨lo, hi, start, stop⟩) ticks labels := rfl

end Inkproof.Demos.Axes
