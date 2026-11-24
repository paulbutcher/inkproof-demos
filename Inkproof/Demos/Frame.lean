/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Gpu.Frame
import Inkproof.Scene
import Inkproof.Float
import Inkproof.Scale
import Inkproof.Viewport
import Inkproof.Demos.Axes

namespace Inkproof.Demos

open Inkproof.Axis Inkproof.Scene Inkproof.Scale Inkproof.Viewport

/-- The page's colour, which every chart is drawn on. -/
def background : Color := ⟨255, 255, 255, 255⟩

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

/-- The view of a chart that cannot be zoomed: its home view is the whole of the frame's ranges. -/
def Frame.viewConfig (f : Frame) : ViewConfig Float :=
  let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
    let span := Rat.toFloat (r.2 - r.1)
    ⟨Rat.toFloat length, span, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
  ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩

theorem Frame.viewConfig_eq (f : Frame) : f.viewConfig =
    let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
      let span := Rat.toFloat (r.2 - r.1)
      ⟨Rat.toFloat length, span, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
    ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩ := rfl

/-- The float scale of the frame's x axis, from data to pixels along the plot. -/
def Frame.xScale (f : Frame) : Linear Float :=
  ⟨Rat.toFloat f.xs.1, Rat.toFloat f.xs.2, Rat.toFloat f.left, Rat.toFloat f.right⟩

theorem Frame.xScale_eq (f : Frame) :
    f.xScale = ⟨Rat.toFloat f.xs.1, Rat.toFloat f.xs.2, Rat.toFloat f.left, Rat.toFloat f.right⟩ := rfl

/-- The float scale of the frame's y axis; pixels grow downwards. -/
def Frame.yScale (f : Frame) : Linear Float :=
  ⟨Rat.toFloat f.ys.1, Rat.toFloat f.ys.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩

theorem Frame.yScale_eq (f : Frame) :
    f.yScale = ⟨Rat.toFloat f.ys.1, Rat.toFloat f.ys.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩ := rfl

/-- The bottom and left axes. -/
def axes (f : Frame) (measure : String → Float × Float) : List AxisDrawing :=
  [compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
   compileLinearAxis .left (plot f) f.yScale Axes.spec measure Axes.style]

theorem axes_eq (f : Frame) (measure : String → Float × Float) :
    axes f measure =
      [compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
       compileLinearAxis .left (plot f) f.yScale Axes.spec measure Axes.style] := rfl

/-- The bottom axis of `f` over Unix times, with ticks at clock intervals, about `target` of them. -/
def Frame.timeAxis (f : Frame) (target : Nat) (measure : String → Float × Float) : AxisDrawing :=
  compileTimeAxis .bottom (plot f) f.xScale { Axes.spec with target } Axes.months measure Axes.style

theorem Frame.timeAxis_eq (f : Frame) (target : Nat) (measure : String → Float × Float) :
    f.timeAxis target measure =
      compileTimeAxis .bottom (plot f) f.xScale { Axes.spec with target } Axes.months measure Axes.style := rfl

/-- The width of the plot in pixels. -/
def Frame.xExtent (f : Frame) : Float := Rat.toFloat (f.right - f.left)

theorem Frame.xExtent_eq (f : Frame) : f.xExtent = Rat.toFloat (f.right - f.left) := rfl

/-- The height of the plot in pixels. -/
def Frame.yExtent (f : Frame) : Float := Rat.toFloat (f.bottom - f.top)

theorem Frame.yExtent_eq (f : Frame) : f.yExtent = Rat.toFloat (f.bottom - f.top) := rfl

/-- The ticks of the bottom axis over Unix times in UTC, at least `Axes.xSpacing` pixels apart, with their labels and contexts. -/
def Frame.spacedTimeTicks (f : Frame) (style : TimeStyle) : List Float × List String × List (Option String) :=
  Axes.spacedTimeTicks style (fun _ => 0) (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) f.xExtent

theorem Frame.spacedTimeTicks_eq (f : Frame) (style : TimeStyle) : f.spacedTimeTicks style =
    Axes.spacedTimeTicks style (fun _ => 0) (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) f.xExtent := rfl

/-- The bottom axis of `f` over Unix times, labelled in `style`. -/
def Frame.spacedTimeAxis (f : Frame) (style : TimeStyle) (measure : String → Float × Float) : AxisDrawing :=
  let (ts, labels, contexts) := f.spacedTimeTicks style
  compilePixelAxis .bottom (plot f) Axes.style measure Axes.spec.labelGap (ts.map f.xScale.map) labels contexts

theorem Frame.spacedTimeAxis_eq (f : Frame) (style : TimeStyle) (measure : String → Float × Float) :
    f.spacedTimeAxis style measure =
      compilePixelAxis .bottom (plot f) Axes.style measure Axes.spec.labelGap
        ((f.spacedTimeTicks style).1.map f.xScale.map) (f.spacedTimeTicks style).2.1 (f.spacedTimeTicks style).2.2 := rfl

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
