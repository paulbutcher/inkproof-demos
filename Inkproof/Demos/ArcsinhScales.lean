/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The data are those of uPlot's `arcsinh-scales` demo, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Float
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines

namespace Inkproof.Demos.ArcsinhScales

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- `1, 2, …, 9` times each power of ten from a thousandth to a hundred, then a thousand. -/
def magnitudes : List Rat :=
  ((List.range 6).flatMap fun e => (List.range 9).map fun i => ((i + 1 : Nat) : Rat) * (10 : Rat) ^ e / 1000) ++ [1000]

/-- The magnitudes mirrored about zero, in increasing order. -/
def values : Array Rat := (magnitudes.reverse.map (- ·) ++ [0] ++ magnitudes).toArray

theorem values_eq : values = (magnitudes.reverse.map (- ·) ++ [0] ++ magnitudes).toArray := rfl

theorem magnitudes_eq : magnitudes =
    ((List.range 6).flatMap fun e => (List.range 9).map fun i => ((i + 1 : Nat) : Rat) * (10 : Rat) ^ e / 1000) ++ [1000] := rfl

/-- The point numbers `1, 2, …`, which are the x values. -/
def times : Array Rat := (Array.range values.size).map fun i => ((i + 1 : Nat) : Rat)

theorem times_eq : times = (Array.range values.size).map fun i => ((i + 1 : Nat) : Rat) := rfl

/-- The linear threshold the slider's position `k` (from -3 to 3) stands for: ten to the `k`. -/
def threshold (k : Int) : Rat :=
  if 0 ≤ k then (10 : Rat) ^ k.toNat else 1 / (10 : Rat) ^ (-k).toNat

theorem threshold_eq (k : Int) : threshold k = if 0 ≤ k then (10 : Rat) ^ k.toNat else 1 / (10 : Rat) ^ (-k).toNat := rfl

def width : Nat := 1600
def height : Nat := 600

def frame : Frame := Frame.sized width height (1, (values.size : Rat)) (-1000, 1000)

theorem frame_eq : frame = Frame.sized width height (1, (values.size : Rat)) (-1000, 1000) := rfl

/-- The arcsinh scale of the y axis for the threshold `k`, from data to pixels. -/
def yScale (k : Int) : Asinh Float :=
  ⟨Rat.toFloat frame.ys.1, Rat.toFloat frame.ys.2, Rat.toFloat frame.bottom, Rat.toFloat frame.top, Rat.toFloat (threshold k)⟩

theorem yScale_eq (k : Int) : yScale k =
    ⟨Rat.toFloat frame.ys.1, Rat.toFloat frame.ys.2, Rat.toFloat frame.bottom, Rat.toFloat frame.top, Rat.toFloat (threshold k)⟩ := rfl

/-- Data to pixels along the y axis. -/
def yPixel (k : Int) : Float → Float := Asinh.map Float.asinh (yScale k)

theorem yPixel_eq (k : Int) : yPixel k = Asinh.map Float.asinh (yScale k) := rfl

/-- The data value at a pixel along the y axis. -/
def yValue (k : Int) : Float → Float := Asinh.unmap Float.asinh Float.sinh (yScale k)

theorem yValue_eq (k : Int) : yValue k = Asinh.unmap Float.asinh Float.sinh (yScale k) := rfl

/-- Ticks at the powers of ten either side of zero, and at zero. -/
def yTicks : List Float :=
  let decades := logTicks 1e-3 1e3 Axes.spec.target
  decades.reverse.map (- ·) ++ [0] ++ decades

theorem yTicks_eq : yTicks =
    (logTicks 1e-3 1e3 Axes.spec.target).reverse.map (- ·) ++ [0] ++ logTicks 1e-3 1e3 Axes.spec.target := rfl

/-- Each tick is written alone, with only the digits it needs, since the ticks span a million-fold range. -/
def yLabels : List String := yTicks.map fun t => (tickLabels Axes.spec.locale [t]).headD ""

theorem yLabels_eq : yLabels = yTicks.map fun t => (tickLabels Axes.spec.locale [t]).headD "" := rfl

/-- Every label the axes may show. -/
def labelTexts : List String := Axes.linearLabels 1 values.size.toFloat ++ yLabels

theorem labelTexts_eq : labelTexts = Axes.linearLabels 1 values.size.toFloat ++ yLabels := rfl

def axes (k : Int) (measure : String → Float × Float) : List AxisDrawing :=
  [compileLinearAxis .bottom (plot frame) frame.xScale Axes.spec measure Axes.style,
   compilePixelAxis .left (plot frame) Axes.style measure Axes.spec.labelGap (yTicks.map (yPixel k)) yLabels]

theorem axes_eq (k : Int) (measure : String → Float × Float) : axes k measure =
    [compileLinearAxis .bottom (plot frame) frame.xScale Axes.spec measure Axes.style,
     compilePixelAxis .left (plot frame) Axes.style measure Axes.spec.labelGap (yTicks.map (yPixel k)) yLabels] := rfl

/-- Data to pixels: the y axis is the arcsinh scale. -/
def projection (k : Int) : Projection Rat Rat :=
  ⟨(Linear.mk frame.xs.1 frame.xs.2 frame.left frame.right).map,
   fun v => (Inkproof.Float.Float.toRat (yPixel k (Rat.toFloat v))).getD 0⟩

theorem projection_y (k : Int) (v : Rat) : (projection k).y v = (Inkproof.Float.Float.toRat (yPixel k (Rat.toFloat v))).getD 0 := rfl

def blue : Color := ⟨0, 0, 255, 255⟩

def data : Core.Series Rat Rat := Lines.series times (values.map some)

theorem data_eq : data = Lines.series times (values.map some) := rfl

/-- The axes, then the line over a faint fill down to the bottom, unless the legend has hidden it. -/
def chart (k : Int) (off : Array Bool) (measure : String → Float × Float) : DisplayList :=
  (axes k measure).foldl (· ++ ·.display) #[] ++
    (if off.getD 0 false then #[]
     else compileArea ⟨0, .flat ⟨0, 0, 255, 26⟩⟩ frame.ys.1 (projection k) (Segmented.single data) ++
          compileLine ⟨⟨1, blue⟩, 1 / 2, false, none, .straight⟩ (projection k) (Segmented.single data))

theorem chart_eq (k : Int) (off : Array Bool) (measure : String → Float × Float) : chart k off measure =
    (axes k measure).foldl (· ++ ·.display) #[] ++
      (if off.getD 0 false then #[]
       else compileArea ⟨0, .flat ⟨0, 0, 255, 26⟩⟩ frame.ys.1 (projection k) (Segmented.single data) ++
            compileLine ⟨⟨1, blue⟩, 1 / 2, false, none, .straight⟩ (projection k) (Segmented.single data)) := rfl

end Inkproof.Demos.ArcsinhScales
