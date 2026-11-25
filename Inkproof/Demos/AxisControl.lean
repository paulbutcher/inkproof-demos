/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import RandomSampling

namespace Inkproof.Demos.AxisControl

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- The number of points of the series: `0` to `n - 1`. -/
def n : Nat := 500001

/-- The signal at `x`: two slow sines and a fast one, as uPlot's page sums them, with `noise` in `[-1/2, 1/2]`. -/
def signal (x : Nat) (noise : Float) : Float :=
  let x := x.toFloat
  noise + Float.sin (x * 0.00002) * 40 + Float.sin (x * 0.001) * 5 + Float.sin (x * 0.1) * 2

theorem signal_eq (x : Nat) (noise : Float) : signal x noise =
    noise + Float.sin (x.toFloat * 0.00002) * 40 + Float.sin (x.toFloat * 0.001) * 5 + Float.sin (x.toFloat * 0.1) * 2 := rfl

/-- A value rounded to thousandths, the exact number the chart plots. -/
def thousandths (v : Float) : Rat := (Rat.ofInt (v * 1000).round.toInt64.toInt) / 1000

theorem thousandths_eq (v : Float) : thousandths v = (Rat.ofInt (v * 1000).round.toInt64.toInt) / 1000 := rfl

/-- The `n` points of the series, the noise drawn from a fixed seed so that every visit shows the same chart. -/
def points : Array (Rat × Option Rat) :=
  (RandomSampling.nats (mkStdGen 3) n 0 1000).1.mapIdx fun x d =>
    ((x : Rat), some (thousandths (signal x (d.toFloat / 1000 - 0.5))))

theorem points_eq : points = (RandomSampling.nats (mkStdGen 3) n 0 1000).1.mapIdx fun x d =>
    ((x : Rat), some (thousandths (signal x (d.toFloat / 1000 - 0.5)))) := rfl

theorem points_size : points.size = n := by
  simp [points, RandomSampling.nats_size]

def series : Series Rat Rat := Series.ofUnsorted points

theorem series_eq : series = Series.ofUnsorted points := rfl

def frame : Frame := ⟨60, 988, 20, 520, (0, 500000), (-50, 50), none⟩

def red : Color := ⟨255, 0, 0, 255⟩

def yTicks : List Float := linearTicks (-50) 50 8

theorem yTicks_eq : yTicks = linearTicks (-50) 50 8 := rfl

def labels : List String := tickLabels .en yTicks

theorem labels_eq : labels = tickLabels .en yTicks := rfl

/-- Every label either axis may show: the browser measures these before the axes choose among them. -/
def labelTexts : List String :=
  Axes.linearLabels (Rat.toFloat frame.xs.1) (Rat.toFloat frame.xs.2) ++ labels

theorem labelTexts_eq : labelTexts =
    Axes.linearLabels (Rat.toFloat frame.xs.1) (Rat.toFloat frame.xs.2) ++ labels := rfl

def axes (measure : String → Float × Float) (theme : Option Theme := none) : List AxisDrawing :=
  [compileLinearAxis .bottom (plot frame) frame.xScale Axes.spec measure (Axes.styled theme),
   compilePixelAxis .right (plot frame) (Axes.styled theme) measure Axes.spec.labelGap (yTicks.map frame.yScale.map) labels]

theorem axes_eq (measure : String → Float × Float) (theme : Option Theme) : axes measure theme =
    [compileLinearAxis .bottom (plot frame) frame.xScale Axes.spec measure (Axes.styled theme),
     compilePixelAxis .right (plot frame) (Axes.styled theme) measure Axes.spec.labelGap (yTicks.map frame.yScale.map) labels] := rfl

/-- The axes, then the series as a line thinned to what its pixel columns show. -/
def chart (measure : String → Float × Float) (theme : Option Theme := none) : DisplayList :=
  (axes measure theme).foldl (· ++ ·.display) #[] ++
  compileLine ⟨⟨1, red⟩, Axes.strokeHalfWidth, true, none, .straight⟩ (projection frame) (Segmented.single series)

theorem chart_eq (measure : String → Float × Float) (theme : Option Theme) : chart measure theme =
    (axes measure theme).foldl (· ++ ·.display) #[] ++
    compileLine ⟨⟨1, red⟩, Axes.strokeHalfWidth, true, none, .straight⟩ (projection frame) (Segmented.single series) := rfl

end Inkproof.Demos.AxisControl
