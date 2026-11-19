/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Float
import Inkproof.Scale
import Inkproof.Demos.Axes

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

/-- A `width` by `height` chart with room for the axes' labels left of and below the plot. -/
def Frame.sized (width height : Nat) (xs ys : Rat × Rat) : Frame :=
  ⟨60, width - 20, 20, height - 40, xs, ys⟩

theorem Frame.sized_eq (width height : Nat) (xs ys : Rat × Rat) :
    Frame.sized width height xs ys = ⟨60, width - 20, 20, height - 40, xs, ys⟩ := rfl

/-- The bottom and left axes. -/
def axes (f : Frame) (measure : String → Float × Float) : List AxisDrawing :=
  [Axes.linear .bottom (plot f) measure (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) (Rat.toFloat f.left) (Rat.toFloat f.right),
   Axes.linear .left (plot f) measure (Rat.toFloat f.ys.1) (Rat.toFloat f.ys.2) (Rat.toFloat f.bottom) (Rat.toFloat f.top)]

theorem axes_eq (f : Frame) (measure : String → Float × Float) :
    axes f measure =
      [Axes.linear .bottom (plot f) measure (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) (Rat.toFloat f.left) (Rat.toFloat f.right),
       Axes.linear .left (plot f) measure (Rat.toFloat f.ys.1) (Rat.toFloat f.ys.2) (Rat.toFloat f.bottom) (Rat.toFloat f.top)] := rfl

/-- The axes' commands, drawn under the data. -/
def axisDisplay (f : Frame) (measure : String → Float × Float) : DisplayList :=
  (axes f measure).foldl (· ++ ·.display) #[]

theorem axisDisplay_eq (f : Frame) (measure : String → Float × Float) :
    axisDisplay f measure = (axes f measure).foldl (· ++ ·.display) #[] := rfl

/-- Every text the axes may label, for the host to measure. -/
def texts (f : Frame) : Array String :=
  (Axes.linearLabels (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) ++ Axes.linearLabels (Rat.toFloat f.ys.1) (Rat.toFloat f.ys.2)).toArray

theorem texts_eq (f : Frame) :
    texts f = (Axes.linearLabels (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) ++ Axes.linearLabels (Rat.toFloat f.ys.1) (Rat.toFloat f.ys.2)).toArray := rfl

end Inkproof.Demos
