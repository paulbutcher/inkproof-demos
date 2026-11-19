/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Scale

namespace Inkproof.Demos

open Inkproof.Scene Inkproof.Scale

/-- Plot rectangle and data ranges of the chart. -/
structure Frame where
  left : Rat
  right : Rat
  top : Rat
  bottom : Rat
  xs : Rat × Rat
  ys : Rat × Rat

/-- Data to pixels: x increases rightwards and y upwards, so the y range is reversed. -/
def projection (f : Frame) : Projection Rat Rat :=
  .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨f.ys.1, f.ys.2, f.bottom, f.top⟩

theorem projection_x (f : Frame) (x : Rat) :
    (projection f).x x = (Linear.mk f.xs.1 f.xs.2 f.left f.right).map x := rfl

theorem projection_y (f : Frame) (y : Rat) :
    (projection f).y y = (Linear.mk f.ys.1 f.ys.2 f.bottom f.top).map y := rfl

def plot (f : Frame) : Rect := ⟨f.left, f.top, f.right, f.bottom⟩

theorem plot_eq (f : Frame) : plot f = ⟨f.left, f.top, f.right, f.bottom⟩ := rfl

end Inkproof.Demos
