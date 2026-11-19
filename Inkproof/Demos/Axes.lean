/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Scale
import Inkproof.Scene
import Inkproof.Web.Access

namespace Inkproof.Demos.Axes

open Inkproof.Scale Inkproof.Scene Inkproof.Axis Inkproof.Web

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

/-- The axis of `side` of `plot` showing the data range `lo` to `hi`, which lies between `start` and `stop` pixels along the plot. -/
def linear (side : Side) (plot : Rect) (measure : String → Float × Float) (lo hi start stop : Float) :
    AxisDrawing :=
  let pixel := (Linear.mk lo hi start stop).map
  let ticks := (linearTicks lo hi 10).map fun v => (pixel v, showFloat v)
  compileAxis side plot plane style (ticks.map (·.1)) (labelLayout side measure ticks)

theorem plane_eq (p : Float) : plane p = (Inkproof.Float.Float.toRat p).getD 0 := rfl

theorem linear_eq (side : Side) (plot : Rect) (measure : String → Float × Float) (lo hi start stop : Float) :
    linear side plot measure lo hi start stop =
      let ticks := (linearTicks lo hi 10).map fun v => ((Linear.mk lo hi start stop).map v, showFloat v)
      compileAxis side plot plane style (ticks.map (·.1)) (labelLayout side measure ticks) := rfl

end Inkproof.Demos.Axes
